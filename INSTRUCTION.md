## 🚀 快速開始

### 前置需求
```bash
# 必要工具
- Git
- GitHub CLI (gh)
- R (4.3.0+)
- 瀏覽器

# 檢查工具版本
git --version
gh --version
R --version
```

### 立即部署
```bash
# 1. 下載專案
git clone https://github.com/your-org/cdc-github-course.git
cd cdc-github-course

# 2. 設定權限
chmod +x scripts/*.sh

# 3. 安裝 R 套件
Rscript -e "
  install.packages(c('tidyverse', 'gh', 'git2r', 'yaml', 
                     'plumber', 'cronR', 'keyring'))
"

# 4. 設定 GitHub 認證
gh auth login
```

## 📋 完整實施流程

### 階段 1: 基礎設施建立 

#### 1.1 GitHub Organization 建置
```bash
# 使用 GitHub 網頁建立 Organization
# 名稱建議: cdc-modeling-hub 或您的機構縮寫
```

#### 1.2 複製核心檔案
```bash
# 複製 GitHub Actions 工作流程
mkdir -p .github/workflows
cp workflows/.github/workflows/* .github/workflows/

# 複製驗證腳本
cp -r validation/ ./

# 複製文件模板
cp docs/CODEOWNERS ./
cp docs/PULL_REQUEST_TEMPLATE.md ./.github/
```

#### 1.3 設定團隊權限
參考 `docs/README.md` 中的團隊結構設定：
- admin-team (管理員)
- maintainers (維護者)
- modelers (建模團隊)
- reviewers (審查員)

### 階段 2: 自動化流程設定 

#### 2.1 資料驗證流程
```bash
# 測試驗證腳本
cd validation
Rscript validate_forecast.R
Rscript run_all_checks.R
```

#### 2.2 設定 GitHub Secrets
在 GitHub Repository Settings → Secrets 中設定：
```
GITHUB_TOKEN: (自動提供)
BACKUP_TOKEN: (用於備份的 PAT)
SLACK_WEBHOOK: (選用，通知用)
```

#### 2.3 啟用 GitHub Actions
推送程式碼後，Actions 會自動啟用：
- ✅ validate-submission.yml
- ✅ backup.yml  
- ✅ deploy-website.yml
- ✅ weekly-integration.yml

### 階段 3: R Server 整合 

#### 3.1 設定 R Server 推送
```r
# 在 R Server 上執行
source("scripts/push_to_github.R")

# 設定安全認證
library(keyring)
key_set("github_pat")  # 輸入您的 GitHub Token

# 測試推送
push_surveillance_data()
```

#### 3.2 設定定期同步
```r
# 設定每日自動推送
source("scripts/push_to_github.R")
setup_scheduled_push()

# 設定雙向同步
source("scripts/sync_with_github.R")
setup_sync_schedule()
```

#### 3.3 啟用 Webhook (選用)
```r
# 啟動 Webhook 接收服務
source("scripts/webhook_api.R")
start_webhook_server(port = 8000)
```

### 階段 4: 網站建置 

#### 4.1 建立網站 Repository
```bash
# 建立專用的網站 Repository
gh repo create your-org/website --public

# 複製網站模板
cp templates/_quarto.yml ./
cp templates/index.qmd ./
cp templates/results.qmd ./
cp templates/styles.css ./
```

#### 4.2 設定 GitHub Pages
```bash
# 啟用 GitHub Pages
gh api repos/your-org/website/pages \
  -f source[branch]=main \
  -f source[path]=/

# 設定自訂網域 (選用)
echo "your-domain.com" > CNAME
```

#### 4.3 部署網站
```bash
# 推送網站檔案
git add .
git commit -m "Initial website setup"
git push

# 網站將自動建置並部署
```

### 階段 5: 備份與安全 

#### 5.1 設定備份機制
```r
# 執行初始備份
source("scripts/backup_critical_data.R")
backup_critical()

# 驗證備份完整性
verify_backup("critical_backup_2025-07-30")
```

#### 5.2 建立災難復原計畫
```bash
# 測試災難復原工具
./scripts/disaster_recovery.sh

# 定期進行復原演練 (每季)
```

#### 5.3 安全性強化
- 啟用 2FA 
- 設定分支保護規則
- 定期權限審查
- 監控存取日誌

### 階段 6: 團隊培訓與上線 

#### 6.1 建立提交模板
```bash
# 從模板建立團隊提交 Repository
gh repo create your-org/forecast-2025-W31-example \
  --template your-org/modeling-template \
  --public
```

#### 6.2 團隊培訓
使用 `scripts/git_basic_operations.sh` 進行基礎培訓：
```bash
# Git 基礎操作示範
bash scripts/git_basic_operations.sh
```

#### 6.3 首次提交測試
按照 `docs/PULL_REQUEST_TEMPLATE.md` 格式進行測試提交

## 📚 技術文件使用順序

### 🔰 新手入門
1. **開始閱讀**: `docs/README.md` - 了解系統架構
2. **實作練習**: `scripts/git_basic_operations.sh` - Git 基礎操作
3. **格式學習**: `docs/example_metadata.yml` - 資料格式範例

### 🏗️ 系統建置
1. **工作流程**: `workflows/.github/workflows/` - 自動化設定
2. **資料驗證**: `validation/` - 品質控制機制
3. **網站建置**: `templates/` - 前端展示

### 🔧 進階整合  
1. **R Server**: `scripts/push_to_github.R` - 資料推送
2. **API 服務**: `scripts/webhook_api.R` - 事件處理
3. **雙向同步**: `scripts/sync_with_github.R` - 完整整合

### 🛡️ 維運管理
1. **備份策略**: `scripts/backup_critical_data.R` - 資料保護
2. **災難復原**: `docs/DISASTER_RECOVERY.md` - 緊急處理
3. **安全管理**: `docs/CODEOWNERS` - 權限控制

## 🎯 常見使用情境

### 情境 1: 新團隊加入
```bash
# 1. 建立團隊 Repository
gh repo create your-org/forecast-2025-W32-newteam \
  --template your-org/modeling-template

# 2. 設定權限
gh api orgs/your-org/teams/modelers/repos/your-org/forecast-2025-W32-newteam \
  -f permission=push -X PUT

# 3. 提供培訓材料
# - docs/README.md
# - docs/example_metadata.yml
# - scripts/git_basic_operations.sh
```

### 情境 2: 資料格式驗證
```r
# 驗證單一檔案
source("validation/validate_forecast.R")
validate_forecast("data-processed/2025-07-30-team-model.csv")

# 批次驗證
validate_all("data-processed", "metadata")
```

### 情境 3: 網站內容更新
```r
# 收集最新預測資料
source("scripts/collect_forecasts.R")
collect_all_forecasts()

# 網站會自動更新 (透過 GitHub Actions)
```

### 情境 4: 系統備份
```r
# 手動備份
source("scripts/backup_critical_data.R")
backup_critical()

# 自動備份已透過 GitHub Actions 設定
```

### 情境 5: 緊急復原
```bash
# 啟動災難復原工具
./scripts/disaster_recovery.sh

# 按選單操作：
# 1. 列出可用備份
# 2. 從備份復原 Repository
# 3. 復原已刪除的 Repository
```

## 🔍 疑難排解

### 常見問題與解決方案

#### ❓ GitHub Actions 失敗
```bash
# 檢查 Secrets 設定
gh secret list

# 查看執行日誌
gh run view [RUN_ID] --log

# 常見解決方法
# 1. 確認 GITHUB_TOKEN 權限
# 2. 檢查 R 套件安裝
# 3. 驗證檔案路徑
```

#### ❓ R 套件安裝問題
```r
# 檢查系統需求
pak::pkg_system_requirements("tidyverse")

# 強制重新安裝
remove.packages("problematic_package")
install.packages("problematic_package")
```

#### ❓ 資料驗證失敗
```r
# 檢查檔案格式
readLines("problematic_file.csv", n = 5)

# 逐步驗證
source("validation/validate_forecast.R")
data <- read.csv("problematic_file.csv")
str(data)  # 檢查資料結構
```

#### ❓ 網站無法更新
```bash
# 檢查 GitHub Pages 狀態
gh api repos/your-org/website/pages

# 手動觸發建置
gh workflow run deploy-website.yml
```

### 🔗 取得協助

1. **查閱文件**: `docs/` 目錄下的詳細文件
2. **檢查範例**: `templates/` 和 `docs/example_metadata.yml`
3. **執行測試**: 使用 `validation/` 下的驗證腳本
4. **聯繫支援**: tech-support@cdc.gov.tw

## 📊 系統監控

### 每日檢查
```bash
# 檢查 Actions 狀態
gh run list --limit 10

# 檢查最新備份
gh release list --limit 5

# 檢查網站狀態
curl -I https://your-website.com
```

### 每週維護
```r
# 產生週報
source("scripts/generate_weekly_report.R")
generate_weekly_report()

# 清理舊備份
source("scripts/backup_critical_data.R")  
cleanup_old_backups()
```

### 每月審查
- 權限審查
- 效能分析
- 安全稽核
- 使用統計

## 🌟 最佳實務

### 開發流程
1. **Fork** → **Branch** → **Commit** → **PR** → **Review** → **Merge**
2. 使用有意義的 commit 訊息
3. 小批次提交，避免大範圍變更
4. 充分的測試與驗證

### 資料管理
1. 統一檔案命名規範
2. 完整的 metadata 描述
3. 定期備份重要資料
4. 版本控制所有變更

### 安全管理
1. 啟用 2FA 認證
2. 定期更新 Token
3. 限制存取權限
4. 監控異常活動

## 📈 擴展功能

### 進階功能建議
1. **API 開發**: RESTful API 提供資料服務
2. **機器學習**: 自動化模型優化
3. **國際合作**: 多語言與跨國資料交換
4. **行動應用**: 手機版監控儀表板

### 整合建議
1. **Slack/Teams**: 即時通知整合
2. **JIRA**: 專案管理整合
3. **Tableau**: 進階視覺化
4. **AWS/Azure**: 雲端運算資源

## 🤝 貢獻指南

歡迎提交改進建議和問題回報！

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 建立 Pull Request
