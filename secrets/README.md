# Docker Secrets for Production

此目錄用於存放生產環境的敏感資訊（Docker Secrets）。

## 安全性說明

**重要：** 真實的 secret 文件（`*.txt`）不會被 git 追蹤，只有範例文件（`*.example`）會被提交。

## 設定步驟

### 1. 創建 Secret 文件

在部署生產環境前，需要先創建實際的 secret 文件：

```bash
# 複製範例文件
cp secrets/mysql_user.txt.example secrets/mysql_user.txt
cp secrets/mysql_password.txt.example secrets/mysql_password.txt
cp secrets/mysql_root_password.txt.example secrets/mysql_root_password.txt
```

### 2. 編輯 Secret 文件

使用安全的密碼編輯器修改文件內容：

```bash
# 設定 MySQL 使用者名稱
echo "your_db_username" > secrets/mysql_user.txt

# 設定 MySQL 使用者密碼（建議使用強密碼）
echo "your_secure_password_here" > secrets/mysql_password.txt

# 設定 MySQL root 密碼
echo "your_secure_root_password_here" > secrets/mysql_root_password.txt
```

**密碼安全建議：**
- 至少 16 個字元
- 包含大小寫字母、數字和特殊符號
- 不要使用字典單詞
- 可使用密碼產生器：`openssl rand -base64 32`

### 3. 設定文件權限

確保只有 owner 可以讀取：

```bash
chmod 600 secrets/*.txt
```

### 4. 啟動生產環境

```bash
docker compose -f compose.prod.yaml up -d
```

## Docker Secrets 運作方式

在生產環境中：

1. **MySQL 容器**：
   - 使用 `MYSQL_USER_FILE`、`MYSQL_PASSWORD_FILE` 和 `MYSQL_ROOT_PASSWORD_FILE` 環境變數
   - Docker 將 secrets 掛載到 `/run/secrets/` 目錄
   - MySQL 從這些文件讀取敏感資訊

2. **應用程式容器**：
   - NestJS 配置 (`src/config/database.config.ts`) 會先嘗試從 `/run/secrets/` 讀取
   - 如果找不到 secrets 文件，則回退到環境變數
   - 這確保了開發和生產環境的兼容性

## 文件說明

- `mysql_user.txt` - MySQL 應用程式使用者名稱
- `mysql_password.txt` - MySQL 應用程式使用者密碼
- `mysql_root_password.txt` - MySQL root 使用者密碼
- `*.example` - 範例文件（會提交到 git）
- `.gitkeep` - 確保空目錄被 git 追蹤

## 常見問題

### Q: 如何在 Docker Swarm 中使用？

```bash
# 創建 Docker Swarm secrets
docker secret create mysql_user secrets/mysql_user.txt
docker secret create mysql_password secrets/mysql_password.txt
docker secret create mysql_root_password secrets/mysql_root_password.txt

# 部署 stack
docker stack deploy -c compose.prod.yaml hr-backend
```

### Q: 如何輪換密碼？

1. 更新 secret 文件內容
2. 重新創建 secret（Docker Swarm）或重啟容器（Docker Compose）
3. 確保應用程式和資料庫都使用新密碼

### Q: 開發環境需要這些文件嗎？

不需要。開發環境使用 `compose.dev.yaml`，直接在 compose 文件中設定密碼。
Docker Secrets 僅用於生產環境。

## 最佳實踐

1. **不要在程式碼中硬編碼密碼**
2. **定期輪換密碼**（建議每 90 天）
3. **使用密碼管理工具**（如 1Password、LastPass）
4. **限制 secret 文件的訪問權限**
5. **在 CI/CD 中使用環境變數或 secret 管理服務**
6. **監控異常的資料庫訪問**
