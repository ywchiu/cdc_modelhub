# 疾管署傳染病建模中心

## 專案概述

本專案為疾病管制署建立的傳染病預測模型協作平台，使用 GitHub 作為核心平台，整合全國頂尖研究團隊的預測模型。

## 🎯 主要功能

- **自動化驗證**: 所有提交的預測資料都會經過自動驗證
- **即時展示**: 預測結果即時更新到公開網站
- **版本控制**: 完整追蹤所有預測結果的歷史變更
- **備份機制**: 多層次備份確保資料安全
- **R Server 整合**: 與現有 R 運算環境無縫整合

## 📋 快速開始

### 1. 環境準備

```bash
# 安裝必要工具
# Git, GitHub CLI, R, RStudio (選用)

# 設定 GitHub 認證
gh auth login
```

### 2. 取得專案

```bash
# 複製專案
git clone https://github.com/cdc-modeling-hub/hub-core.git
cd hub-core

# 安裝 R 套件
Rscript -e "source('setup/install_packages.R')"
```

### 3. 執行驗證

```bash
# 驗證環境設定
Rscript validation/run_all_checks.R

# 測試自動化流程
./scripts/test_workflows.sh
```

## 🏗️ 系統架構

```
疾管署 Modeling Hub
├── 🏢 GitHub Organization
│   ├── hub-core/              # 核心管理程式
│   ├── data-repository/       # 資料倉儲
│   ├── website/              # 公開網站
│   └── forecast-YYYY-WW-*/   # 各團隊提交
├── 🤖 自動化流程
│   ├── 資料驗證
│   ├── 網站更新
│   └── 備份作業
└── 🔗 R Server 整合
    ├── 資料推送
    ├── 事件觸發
    └── 結果同步
```

## 📊 資料格式

### 預測資料格式 (CSV)

```csv
forecast_date,target,target_end_date,location,type,quantile,value
2025-07-29,1 wk ahead cases,2025-08-05,TW,point,NA,1523
2025-07-29,1 wk ahead cases,2025-08-05,TW,quantile,0.025,1200
2025-07-29,1 wk ahead cases,2025-08-05,TW,quantile,0.500,1523
```

### 模型 Metadata (YAML)

```yaml
team_name: "國立台灣大學統計系"
team_abbr: "NTU-Stats"
model_name: "SEIR Ensemble Model"
model_version: "2.1.0"
methods: |
  使用 SEIR 區室模型結合機器學習
  整合氣象資料與人口流動數據
data_inputs: |
  - 疾管署每日確診數
  - 中央氣象局溫濕度資料
```

## 🚀 提交流程

### 1. 建立提交 Repository

```bash
# 從模板建立新 repo
gh repo create cdc-modeling-hub/forecast-2025-W31-yourteam \
  --template cdc-modeling-hub/modeling-template \
  --public
```

### 2. 準備資料

```bash
# 檢查目錄結構
forecast-2025-W31-yourteam/
├── data-processed/
│   └── 2025-07-29-yourteam-model.csv
├── metadata/
│   └── yourteam-model.yml
└── README.md
```

### 3. 提交與驗證

```bash
# 提交資料
git add .
git commit -m "Add weekly forecast W31"
git push

# 建立 Pull Request
gh pr create --title "W31 Forecast Submission" \
  --body "本週預測提交，已通過本地驗證"
```

## 🔧 開發指南

### 本地開發環境

```bash
# 安裝開發套件
Rscript -e "install.packages(c('devtools', 'testthat', 'lintr'))"

# 執行測試
Rscript -e "testthat::test_dir('tests')"

# 程式碼檢查
Rscript -e "lintr::lint_dir('.')"
```

### 自訂驗證規則

在 `validation/custom_rules.R` 中加入自訂驗證：

```r
# 自訂驗證規則
validate_custom <- function(data) {
  # 檢查地區代碼
  valid_locations <- c("TW", "TPE", "TXG", "KHH")
  if (!all(data$location %in% valid_locations)) {
    stop("無效的地區代碼")
  }
  
  return(TRUE)
}
```

## 📚 進階功能

### R Server 整合

```r
# 設定自動推送
library(cronR)
cron_add(
  command = cron_rscript("scripts/push_to_github.R"),
  frequency = "daily",
  at = "08:00"
)

# 設定 Webhook 接收
source("scripts/webhook_api.R")
start_webhook_server(port = 8000)
```

### 備份與復原

```bash
# 執行備份
Rscript scripts/backup_critical_data.R

# 災難復原
./scripts/disaster_recovery.sh
```

## 🔍 監控與維運

### 日常檢查清單

- [ ] GitHub Actions 執行狀態
- [ ] 網站更新狀況
- [ ] 備份作業完成
- [ ] R Server 連線正常

### 效能監控

```r
# 產生效能報告
source("scripts/generate_performance_report.R")
generate_weekly_report()
```

## 🆘 疑難排解

### 常見問題

**Q: GitHub Actions 失敗**
```bash
# 檢查 Secrets 設定
gh secret list

# 查看執行日誌
gh run list --limit 5
gh run view [RUN_ID]
```

**Q: R 套件安裝失敗**
```r
# 檢查系統相依性
install.packages("pak")
pak::pkg_system_requirements("tidyverse")
```

**Q: 網站無法更新**
```bash
# 檢查 GitHub Pages 設定
gh api repos/cdc-modeling-hub/website/pages
```

## 📞 技術支援

- **平台管理員**: admin@cdc.gov.tw
- **技術支援**: tech-support@cdc.gov.tw
- **GitHub Issues**: https://github.com/cdc-modeling-hub/hub-core/issues

## 📄 授權

本專案採用 MIT 授權條款。詳見 [LICENSE](LICENSE) 檔案。

## 🙏 貢獻指南

歡迎提交 Issue 和 Pull Request！請先閱讀 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

*最後更新: 2025-07-30*