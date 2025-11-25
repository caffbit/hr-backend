# 生產環境部署指南

本文檔說明如何安全地部署 HR Backend 到生產環境。

## 安全功能

本專案使用 **Docker Secrets** 來管理生產環境的敏感資訊，包括：
- MySQL 使用者名稱
- MySQL 使用者密碼
- MySQL root 密碼

這比使用環境變數更安全，因為：
1. Secrets 不會出現在容器的環境變數中
2. 只存在於記憶體中的加密檔案系統
3. 只有需要的服務才能訪問特定的 secrets

## 部署前準備

### 1. 設定 Docker Secrets

```bash
# 進入專案目錄
cd /Users/callum/Developer/hr-backend

# 創建 secrets 文件
cp secrets/mysql_user.txt.example secrets/mysql_user.txt
cp secrets/mysql_password.txt.example secrets/mysql_password.txt
cp secrets/mysql_root_password.txt.example secrets/mysql_root_password.txt
```

### 2. 生成強密碼

```bash
# 使用 openssl 生成隨機密碼
openssl rand -base64 32 > secrets/mysql_password.txt
openssl rand -base64 32 > secrets/mysql_root_password.txt

# 設定使用者名稱
echo "hr_prod_user" > secrets/mysql_user.txt
```

### 3. 設定文件權限

```bash
chmod 600 secrets/*.txt
```

### 4. 設定環境變數（可選）

創建 `.env.production` 文件：

```env
# 資料庫配置
DB_DATABASE=hr_production

# 應用程式配置
NODE_ENV=production
PORT=3000
```

## 部署步驟

### 使用 Docker Compose

```bash
# 1. 構建生產映像
docker compose -f compose.prod.yaml build

# 2. 啟動服務
docker compose -f compose.prod.yaml up -d

# 3. 檢查服務狀態
docker compose -f compose.prod.yaml ps

# 4. 查看日誌
docker compose -f compose.prod.yaml logs -f app
```

### 使用 Docker Swarm

```bash
# 1. 初始化 Swarm（如果尚未初始化）
docker swarm init

# 2. 創建 Docker Secrets
docker secret create mysql_user secrets/mysql_user.txt
docker secret create mysql_password secrets/mysql_password.txt
docker secret create mysql_root_password secrets/mysql_root_password.txt

# 3. 部署 Stack
docker stack deploy -c compose.prod.yaml hr-backend

# 4. 檢查服務
docker stack services hr-backend

# 5. 查看日誌
docker service logs hr-backend_app -f
```

## 資料庫遷移

### 執行遷移

```bash
# 方法 1: 在運行的容器中執行
docker exec hr-backend-prod pnpm run migration:run

# 方法 2: 進入容器執行
docker exec -it hr-backend-prod sh
pnpm run migration:run
exit
```

### 查看遷移狀態

```bash
docker exec hr-backend-prod pnpm run migration:show
```

### 回滾遷移

```bash
docker exec hr-backend-prod pnpm run migration:revert
```

## 驗證部署

### 1. 檢查應用程式健康狀態

```bash
curl http://localhost:3000
# 應返回: Hello World!
```

### 2. 檢查資料庫連接

```bash
# 查看應用程式日誌，應該看到：
# [TypeORM] Database connection established
docker logs hr-backend-prod | grep TypeORM
```

### 3. 檢查 MySQL 容器

```bash
# 檢查健康狀態
docker inspect hr-mysql-prod | grep -A 5 Health

# 連接到 MySQL（使用 secret）
MYSQL_USER=$(cat secrets/mysql_user.txt)
MYSQL_PASSWORD=$(cat secrets/mysql_password.txt)
docker exec hr-mysql-prod mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" hr_production -e "SHOW TABLES;"
```

## 監控與維護

### 查看日誌

```bash
# 應用程式日誌
docker logs hr-backend-prod -f --tail 100

# 資料庫日誌
docker logs hr-mysql-prod -f --tail 100
```

### 資料庫備份

```bash
# 創建備份
MYSQL_USER=$(cat secrets/mysql_user.txt)
MYSQL_PASSWORD=$(cat secrets/mysql_password.txt)
docker exec hr-mysql-prod mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" hr_production > backup_$(date +%Y%m%d_%H%M%S).sql

# 恢復備份
docker exec -i hr-mysql-prod mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" hr_production < backup_20241126_120000.sql
```

### 更新應用程式

```bash
# 1. 拉取最新代碼
git pull

# 2. 重新構建
docker compose -f compose.prod.yaml build

# 3. 重啟服務（零停機）
docker compose -f compose.prod.yaml up -d --no-deps --build app

# 4. 執行遷移（如有需要）
docker exec hr-backend-prod pnpm run migration:run
```

## 擴展和優化

### 水平擴展應用程式

```bash
# 使用 Docker Compose
docker compose -f compose.prod.yaml up -d --scale app=3

# 使用 Docker Swarm
docker service scale hr-backend_app=3
```

### 資料庫性能優化

在 `compose.prod.yaml` 中調整 MySQL 配置：

```yaml
command:
  - --default-authentication-plugin=mysql_native_password
  - --max_connections=200
  - --innodb_buffer_pool_size=1G
  - --query_cache_size=64M
```

## 安全最佳實踐

1. **定期更新密碼**
   ```bash
   # 生成新密碼
   openssl rand -base64 32 > secrets/mysql_password.txt.new
   # 更新資料庫並重啟服務
   ```

2. **限制網路訪問**
   - 在生產環境中，不要公開 MySQL port (3306)
   - 使用防火牆規則限制訪問

3. **啟用 SSL/TLS**
   - 配置 MySQL SSL 連接
   - 為應用程式啟用 HTTPS

4. **定期備份**
   - 設定自動備份 cron job
   - 測試備份恢復流程

5. **監控和警報**
   - 設定資源使用監控
   - 配置錯誤日誌警報

## 故障排除

### 應用程式無法連接到資料庫

```bash
# 1. 檢查 MySQL 容器狀態
docker ps -a | grep mysql

# 2. 檢查網路連接
docker exec hr-backend-prod ping mysql

# 3. 驗證 secrets 是否正確掛載
docker exec hr-backend-prod ls -la /run/secrets/
docker exec hr-backend-prod cat /run/secrets/mysql_user
```

### Secret 文件更新後未生效

```bash
# 完全重啟服務
docker compose -f compose.prod.yaml down
docker compose -f compose.prod.yaml up -d
```

### 資料庫遷移失敗

```bash
# 查看詳細錯誤
docker exec hr-backend-prod pnpm run migration:show

# 檢查資料庫表
MYSQL_USER=$(cat secrets/mysql_user.txt)
MYSQL_PASSWORD=$(cat secrets/mysql_password.txt)
docker exec hr-mysql-prod mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" hr_production -e "SHOW TABLES;"
```

## 環境對比

| 功能 | 開發環境 | 生產環境 |
|------|---------|---------|
| Compose 文件 | `compose.dev.yaml` | `compose.prod.yaml` |
| 密碼管理 | 環境變數 | Docker Secrets |
| MySQL Port | 公開 (3306) | 內部網路 |
| 日誌級別 | DEBUG | INFO/WARN |
| Hot Reload | 啟用 | 禁用 |
| 資料持久化 | 開發卷 | 生產卷 |

## 參考資源

- [Docker Secrets 文檔](https://docs.docker.com/engine/swarm/secrets/)
- [MySQL Docker 官方映像](https://hub.docker.com/_/mysql)
- [NestJS 生產部署](https://docs.nestjs.com/deployment)
- [TypeORM 遷移指南](https://typeorm.io/migrations)
