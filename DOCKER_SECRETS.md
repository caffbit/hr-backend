# Docker Secrets 實作說明

## 什麼是 Docker Secrets？

Docker Secrets 是 Docker 提供的安全機制，用於管理敏感資料（如密碼、API keys、憑證等）。

### 為什麼使用 Docker Secrets？

**比環境變數更安全的原因：**

1. **不會暴露在環境變數中**
   - `docker inspect` 無法看到 secret 內容
   - `env` 命令看不到敏感資訊
   - 容器日誌不會記錄 secrets

2. **加密存儲**
   - Secrets 儲存在加密的內存檔案系統（tmpfs）
   - 容器重啟後自動清除
   - 永不寫入磁碟

3. **訪問控制**
   - 只有明確授權的服務才能訪問特定 secrets
   - 最小權限原則

## 本專案的實作

### 架構設計

```
┌─────────────────────────────────────────────────┐
│ Host Machine                                    │
│                                                 │
│  secrets/                                       │
│  ├── mysql_user.txt          (git-ignored)      │
│  ├── mysql_password.txt      (git-ignored)      │
│  ├── mysql_root_password.txt (git-ignored)      │
│  └── *.example               (committed)        │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ Docker Compose                          │   │
│  │                                         │   │
│  │  ┌─────────────────────────────────┐   │   │
│  │  │ MySQL Container                 │   │   │
│  │  │                                 │   │   │
│  │  │  /run/secrets/                  │   │   │
│  │  │  ├── mysql_user          (ro)   │   │   │
│  │  │  ├── mysql_password      (ro)   │   │   │
│  │  │  └── mysql_root_password (ro)   │   │   │
│  │  │                                 │   │   │
│  │  │  MySQL uses:                    │   │   │
│  │  │  MYSQL_USER_FILE=/run/secrets/  │   │   │
│  │  │             mysql_user          │   │   │
│  │  └─────────────────────────────────┘   │   │
│  │                                         │   │
│  │  ┌─────────────────────────────────┐   │   │
│  │  │ App Container                   │   │   │
│  │  │                                 │   │   │
│  │  │  /run/secrets/                  │   │   │
│  │  │  ├── mysql_user          (ro)   │   │   │
│  │  │  └── mysql_password      (ro)   │   │   │
│  │  │                                 │   │   │
│  │  │  NestJS config reads from:      │   │   │
│  │  │  database.config.ts             │   │   │
│  │  │  └─> getSecret() function       │   │   │
│  │  └─────────────────────────────────┘   │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### 檔案結構

```
hr-backend/
├── compose.prod.yaml           # 定義 secrets 使用
├── secrets/
│   ├── README.md              # Secret 使用說明
│   ├── .gitkeep               # 確保目錄被追蹤
│   ├── *.txt.example          # 範例文件（提交到 git）
│   └── *.txt                  # 實際 secrets（不提交）
├── src/
│   └── config/
│       └── database.config.ts # 讀取 secrets 的邏輯
└── scripts/
    └── setup-secrets.sh       # 初始化腳本
```

## 關鍵實作細節

### 1. Docker Compose 配置 (compose.prod.yaml)

```yaml
services:
  mysql:
    environment:
      # 使用 _FILE 後綴告訴 MySQL 從文件讀取
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
      MYSQL_USER_FILE: /run/secrets/mysql_user
      MYSQL_PASSWORD_FILE: /run/secrets/mysql_password
    secrets:
      - mysql_root_password
      - mysql_user
      - mysql_password

  app:
    secrets:
      - mysql_user
      - mysql_password

# 定義 secrets 來源
secrets:
  mysql_user:
    file: ./secrets/mysql_user.txt
  mysql_password:
    file: ./secrets/mysql_password.txt
  mysql_root_password:
    file: ./secrets/mysql_root_password.txt
```

### 2. NestJS 配置 (database.config.ts)

```typescript
function getSecret(secretName: string, fallback?: string): string {
  try {
    const secretPath = `/run/secrets/${secretName}`;
    return readFileSync(secretPath, 'utf8').trim();
  } catch {
    return fallback || '';
  }
}

export default registerAs('database', (): DataSourceOptions => {
  // 優先從 Docker secrets 讀取
  const username = getSecret('mysql_user') || process.env.DB_USERNAME || 'root';
  const password = getSecret('mysql_password') || process.env.DB_PASSWORD || '';

  return {
    username,
    password,
    // ...其他配置
  };
});
```

**容錯機制（Fallback）：**
1. 先嘗試從 `/run/secrets/` 讀取（生產環境）
2. 如果失敗，使用環境變數（開發環境）
3. 最後使用預設值

### 3. Health Check 配置

```yaml
healthcheck:
  # 使用 shell 命令替換從 secret 讀取密碼
  test: ["CMD", "sh", "-c", "mysqladmin ping -h localhost -u $$(cat /run/secrets/mysql_user) -p$$(cat /run/secrets/mysql_password)"]
```

**重點：**
- 使用 `sh -c` 執行命令
- `$$` 轉義在 YAML 中正確處理
- `cat /run/secrets/...` 讀取 secret 內容

## 開發 vs 生產環境對比

| 特性 | 開發環境 | 生產環境 |
|-----|---------|---------|
| **密碼管理** | 環境變數（Compose 文件中） | Docker Secrets |
| **密碼儲存** | 明文在 `compose.dev.yaml` | 加密在 tmpfs |
| **密碼可見性** | `docker inspect` 可見 | `docker inspect` 不可見 |
| **配置文件** | `compose.dev.yaml` | `compose.prod.yaml` |
| **適用場景** | 本地開發、測試 | 正式環境、預生產環境 |

## 安全最佳實踐

### ✅ 應該做的

1. **使用強密碼**
   ```bash
   # 生成 32 位元隨機密碼
   openssl rand -base64 32 > secrets/mysql_password.txt
   ```

2. **設定正確的文件權限**
   ```bash
   chmod 600 secrets/*.txt
   ```

3. **在 .gitignore 中排除實際密碼文件**
   ```gitignore
   secrets/*.txt
   !secrets/*.example
   ```

4. **定期輪換密碼**
   - 建議每 90 天更換一次
   - 記錄輪換日期

5. **使用密碼管理器**
   - 將生產密碼存儲在 1Password、LastPass 等工具中
   - 團隊成員通過密碼管理器共享

### ❌ 不應該做的

1. **不要將 `*.txt` 文件提交到 git**
   - 只提交 `*.example` 範例文件

2. **不要在日誌中輸出密碼**
   ```typescript
   // ❌ 錯誤
   console.log('Password:', password);

   // ✅ 正確
   console.log('Database connection established');
   ```

3. **不要使用弱密碼**
   - ❌ `123456`, `password`, `admin`
   - ✅ 隨機生成的強密碼

4. **不要在多個環境使用相同密碼**
   - 開發、測試、生產環境應使用不同的密碼

## 常見問題 (FAQ)

### Q1: 開發環境需要設定 Docker Secrets 嗎？

**A:** 不需要。開發環境使用 `compose.dev.yaml`，直接在文件中設定簡單的密碼即可。Docker Secrets 僅用於生產環境。

### Q2: 如何在 CI/CD 中使用 Docker Secrets？

**A:** 常見做法：

1. **GitHub Actions / GitLab CI**
   ```yaml
   # 使用 repository secrets
   - name: Create secrets
     run: |
       echo "${{ secrets.MYSQL_PASSWORD }}" > secrets/mysql_password.txt
   ```

2. **Jenkins**
   ```groovy
   withCredentials([string(credentialsId: 'mysql-password', variable: 'MYSQL_PWD')]) {
       sh 'echo $MYSQL_PWD > secrets/mysql_password.txt'
   }
   ```

### Q3: Docker Swarm 和 Docker Compose 的 secrets 有什麼不同？

**A:**

| 功能 | Docker Compose | Docker Swarm |
|-----|----------------|--------------|
| **Secret 儲存** | 本地文件 | 加密的 Raft store |
| **適用場景** | 單機部署 | 集群部署 |
| **建立方式** | `file:` 路徑 | `docker secret create` |
| **安全等級** | 高 | 更高 |

### Q4: 如何備份生產環境的密碼？

**A:**

1. **使用密碼管理器** (推薦)
   - 將所有生產密碼存入 1Password/LastPass
   - 團隊成員可以安全存取

2. **加密備份**
   ```bash
   # 使用 GPG 加密
   tar czf - secrets/*.txt | gpg -c > secrets-backup.tar.gz.gpg

   # 解密恢復
   gpg -d secrets-backup.tar.gz.gpg | tar xzf -
   ```

### Q5: 忘記生產環境密碼怎麼辦？

**A:** 如果無法恢復密碼，需要重置：

```bash
# 1. 停止服務
docker compose -f compose.prod.yaml down

# 2. 生成新密碼
openssl rand -base64 32 > secrets/mysql_password.txt

# 3. 重新創建 MySQL 容器（會重置資料庫）
docker compose -f compose.prod.yaml up -d mysql

# ⚠️ 警告：這會丟失所有資料！
# 生產環境應該：
# 1. 從備份恢復
# 2. 或者手動進入 MySQL 容器更改密碼
```

## 監控和稽核

### 記錄密碼使用

在應用程式中記錄密碼存取（不記錄實際密碼）：

```typescript
function getSecret(secretName: string, fallback?: string): string {
  try {
    const secretPath = `/run/secrets/${secretName}`;
    const value = readFileSync(secretPath, 'utf8').trim();

    // 記錄 secret 被存取（不記錄內容）
    console.log(`Secret loaded: ${secretName}`);

    return value;
  } catch (error) {
    console.warn(`Failed to load secret: ${secretName}, using fallback`);
    return fallback || '';
  }
}
```

### 定期稽核

1. 檢查 secret 文件權限：`ls -la secrets/`
2. 檢查 `.gitignore` 是否正確
3. 查看誰有權限存取密碼文件

## 遷移指南

### 從環境變數遷移到 Docker Secrets

**步驟：**

1. **準備 secret 文件**
   ```bash
   echo "$DB_PASSWORD" > secrets/mysql_password.txt
   chmod 600 secrets/mysql_password.txt
   ```

2. **更新 compose 文件**
   ```yaml
   # 移除環境變數
   environment:
     - DB_PASSWORD=${DB_PASSWORD}  # 刪除這行

   # 添加 secrets
   secrets:
     - mysql_password
   ```

3. **更新應用程式代碼**
   - 添加 `getSecret()` 函數
   - 修改配置讀取邏輯

4. **測試**
   ```bash
   docker compose -f compose.prod.yaml up -d
   docker logs hr-backend-prod | grep "Database connection"
   ```

## 總結

Docker Secrets 提供了一個安全、可靠的方式來管理生產環境的敏感資訊。本專案的實作：

✅ **安全性**: 密碼不暴露在環境變數或日誌中
✅ **靈活性**: 支援開發和生產環境的不同配置
✅ **易用性**: 提供腳本自動化設定流程
✅ **可維護性**: 清晰的文檔和範例

遵循本文檔的最佳實踐，可以確保應用程式的密碼管理既安全又方便。
