# DevContainer 配置說明

本專案使用 VS Code Dev Containers 提供一致的開發環境。

## 配置概覽

### 容器架構

```
┌─────────────────────────────────────────────────┐
│ VS Code DevContainer                            │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ App Container (hr-backend-dev)          │   │
│  │                                         │   │
│  │  - NestJS Development Environment       │   │
│  │  - Node.js 20 Alpine                    │   │
│  │  - PNPM package manager                 │   │
│  │  - Hot reload enabled                   │   │
│  │  - VS Code Server                       │   │
│  │                                         │   │
│  │  Workspace: /app                        │   │
│  │  User: node                             │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ MySQL Container (hr-mysql-dev)          │   │
│  │                                         │   │
│  │  - MySQL 8.0                            │   │
│  │  - Database: hr_database                │   │
│  │  - User: hr_user                        │   │
│  │  - Health check enabled                 │   │
│  │                                         │   │
│  │  Network: hr-network                    │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## 改進內容

### ✨ 新增功能

1. **MySQL Port Forwarding (3306)**
   - 可從 VS Code 直接連接到 MySQL
   - 支援使用資料庫管理工具

2. **資料庫管理工具擴充套件**
   - `cweijan.vscode-mysql-client2` - 在 VS Code 內管理 MySQL

3. **NestJS/TypeScript 開發擴充套件**
   - `dbaeumer.vscode-eslint` - ESLint 整合
   - `esbenp.prettier-vscode` - 程式碼格式化

4. **格式化設定**
   - TypeScript 和 JSON 檔案自動使用 Prettier

### 📋 已有功能

- ✅ 自動啟動 MySQL 和應用程式容器
- ✅ MySQL health check 確保資料庫就緒後才啟動應用
- ✅ Volume 掛載支援 hot reload
- ✅ 自動安裝依賴 (`pnpm install`)
- ✅ Git 工具和程式碼品質工具

## 使用方式

### 1. 啟動 DevContainer

**方法 A: 使用 VS Code 命令**
1. 開啟專案資料夾
2. 按 `F1` 或 `Cmd+Shift+P`
3. 選擇 `Dev Containers: Reopen in Container`

**方法 B: 點擊通知**
- VS Code 會自動偵測 `.devcontainer` 並提示重新開啟

### 2. 等待容器啟動

DevContainer 會自動：
1. 構建 app 容器（首次需要幾分鐘）
2. 啟動 MySQL 容器
3. 等待 MySQL health check 通過
4. 啟動應用程式
5. 執行 `pnpm install`
6. 安裝 VS Code 擴充套件

### 3. 驗證環境

啟動後，檢查：

```bash
# 檢查 Node 版本
node --version  # 應該是 v20.x

# 檢查 PNPM
pnpm --version

# 檢查資料庫連接
docker ps  # 應看到 hr-mysql-dev 和 hr-backend-dev
```

### 4. 開發工作流程

```bash
# 應用程式已自動啟動（hot reload 模式）
# 查看日誌
docker logs hr-backend-dev -f

# 執行測試
pnpm run test

# 建立資料庫遷移
pnpm run migration:generate src/database/migrations/MigrationName

# 執行遷移
pnpm run migration:run
```

## 連接 MySQL

### 使用 VS Code MySQL 擴充套件

1. 點擊左側活動欄的 **MySQL** 圖示
2. 點擊 **+** 建立新連接
3. 輸入連接資訊：

```
Host: localhost
Port: 3306
Username: hr_user
Password: hr_password_dev_123
Database: hr_database
```

### 使用命令列

```bash
# 從 app 容器連接（推薦）
docker exec -it hr-backend-dev sh
mysql -h mysql -u hr_user -phr_password_dev_123 hr_database

# 從本機連接
mysql -h 127.0.0.1 -P 3306 -u hr_user -phr_password_dev_123 hr_database
```

### 使用其他 GUI 工具

- **MySQL Workbench**
- **DBeaver**
- **TablePlus**

連接參數：
- Host: `localhost` (或 `127.0.0.1`)
- Port: `3306`
- User: `hr_user`
- Password: `hr_password_dev_123`
- Database: `hr_database`

## 已安裝的 VS Code 擴充套件

### Git 工具
- **GitLens** - Git 超能力
- **Git Graph** - 視覺化 Git 歷史

### 開發體驗
- **Path Intellisense** - 路徑自動完成
- **Code Spell Checker** - 拼寫檢查
- **Todo Highlight** - TODO 高亮顯示
- **Error Lens** - 行內錯誤顯示
- **Color Highlight** - 顏色預覽
- **Material Icon Theme** - 檔案圖示主題

### NestJS / TypeScript
- **ESLint** - 程式碼品質檢查
- **Prettier** - 程式碼格式化

### 資料庫
- **MySQL Client** - MySQL 資料庫管理

## 環境變數

環境變數在 `compose.dev.yaml` 中定義：

```yaml
environment:
  - NODE_ENV=development
  - PORT=3000
  - DB_TYPE=mysql
  - DB_HOST=mysql
  - DB_PORT=3306
  - DB_USERNAME=hr_user
  - DB_PASSWORD=hr_password_dev_123
  - DB_DATABASE=hr_database
  - DB_SYNCHRONIZE=false
  - DB_LOGGING=true
```

## 常見問題

### Q1: 容器啟動失敗？

**解決方案：**
```bash
# 清理並重建
docker compose -f compose.dev.yaml down -v
docker compose -f compose.dev.yaml build --no-cache
```

然後重新開啟 DevContainer。

### Q2: 資料庫連接失敗？

**檢查項目：**
1. MySQL 容器是否健康？
   ```bash
   docker ps  # 檢查 hr-mysql-dev 狀態
   ```

2. Health check 是否通過？
   ```bash
   docker inspect hr-mysql-dev | grep Health
   ```

3. 網路連接是否正常？
   ```bash
   docker exec hr-backend-dev ping mysql
   ```

### Q3: 修改 devcontainer.json 後如何生效？

1. 按 `F1` 打開命令面板
2. 選擇 `Dev Containers: Rebuild Container`
3. 等待容器重建完成

### Q4: 如何退出 DevContainer？

**方法 A: 關閉 VS Code**
- 容器會繼續在背景運行

**方法 B: 重新開啟本機資料夾**
1. 按 `F1`
2. 選擇 `Dev Containers: Reopen Folder Locally`

**方法 C: 完全停止容器**
```bash
docker compose -f compose.dev.yaml down
```

### Q5: 如何更新依賴？

```bash
# 在容器內執行
pnpm install

# 或重建容器
# F1 -> Dev Containers: Rebuild Container
```

## 效能優化

### 加速容器啟動

1. **使用命名卷（已配置）**
   ```yaml
   volumes:
     - mysql_data_dev:/var/lib/mysql  # ✅ 持久化資料
   ```

2. **保護 node_modules**
   ```yaml
   volumes:
     - .:/app
     - /app/node_modules  # ✅ 防止被覆蓋
   ```

3. **使用 BuildKit**
   ```bash
   export DOCKER_BUILDKIT=1
   ```

### 減少重建時間

- 修改原始碼：**不需要重建**（hot reload）
- 修改 `package.json`：**需要** `pnpm install`
- 修改 `Dockerfile`：**需要重建容器**
- 修改 `devcontainer.json`：**需要重建容器**

## 與標準 Docker Compose 的差異

| 功能 | DevContainer | Docker Compose |
|------|-------------|----------------|
| **啟動方式** | VS Code 自動 | 手動 `docker compose up` |
| **VS Code Server** | ✅ 內建 | ❌ 需手動配置 |
| **擴充套件同步** | ✅ 自動安裝 | ❌ 不支援 |
| **Port Forwarding** | ✅ 自動 | ⚠️ 需手動配置 |
| **工作目錄** | ✅ 自動掛載 | ⚠️ 需手動配置 |
| **適用場景** | VS Code 開發 | 任何環境 |

## 最佳實踐

### ✅ 建議

1. **使用 DevContainer 進行日常開發**
   - 環境一致性
   - 擴充套件自動配置
   - 更好的整合體驗

2. **定期更新基礎映像**
   ```bash
   docker compose -f compose.dev.yaml build --pull
   ```

3. **使用 .dockerignore**
   - 避免不必要的檔案進入容器
   - 加速構建過程

4. **定期清理 Docker 資源**
   ```bash
   docker system prune -a --volumes
   ```

### ❌ 避免

1. **不要在容器內修改系統設定**
   - 修改應寫在 `Dockerfile` 或 `devcontainer.json`

2. **不要將敏感資訊寫在 devcontainer.json**
   - 使用環境變數或 secrets

3. **不要忽略 Docker 資源限制**
   - 監控 Docker Desktop 的資源使用

## 故障排除

### 日誌查看

```bash
# 應用程式日誌
docker logs hr-backend-dev -f

# MySQL 日誌
docker logs hr-mysql-dev -f

# 所有服務日誌
docker compose -f compose.dev.yaml logs -f
```

### 重置環境

```bash
# 完全清理（會刪除資料庫資料！）
docker compose -f compose.dev.yaml down -v
docker compose -f compose.dev.yaml up -d

# 在 VS Code 中重建
# F1 -> Dev Containers: Rebuild Container
```

## 進階配置

### 自訂容器生命週期

在 `devcontainer.json` 中：

```json
{
  "postCreateCommand": "pnpm install",           // 容器首次創建後
  "postStartCommand": "echo 'Container started'", // 容器每次啟動後
  "postAttachCommand": "echo 'VS Code attached'"  // VS Code 連接後
}
```

### 掛載額外卷

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/node/.ssh,type=bind,readonly"
  ]
}
```

## 參考資源

- [VS Code Dev Containers 文檔](https://code.visualstudio.com/docs/devcontainers/containers)
- [Docker Compose 文檔](https://docs.docker.com/compose/)
- [NestJS 文檔](https://docs.nestjs.com/)
- [TypeORM 文檔](https://typeorm.io/)
