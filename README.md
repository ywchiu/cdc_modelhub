# 零成本用 GitHub 打造傳染病模型 Modeling Hub

## 實作步驟

[實作步驟](https://github.com/ywchiu/cdc_modelhub/blob/main/INSTRUCTION.md)

## 課程大綱

### 🔧 第一階段：基礎概念 (45分鐘)
- **Git 版本控制系統**
  - 什麼是 Git？解決版本混亂問題
  - 基礎操作：init → add → commit → push
  - 實戰練習：建立預測模型版本控制

- **GitHub 平台介紹**
  - Git vs GitHub 差異解析
  - GitHub 核心功能導覽
  - 成功案例：國際 Forecast Hub

### 🛠️ 第二階段：實戰建置 (50分鐘)
- **Organization 架構設計**
  - 權限管理策略
  - Repository 標準化
  - 團隊協作流程

- **自動化工作流程**
  - GitHub Actions 入門
  - CI/CD 概念與實作
  - 資料驗證自動化

### 🌐 第三階段：進階應用 (30分鐘)
- **專業網站建置**
  - GitHub Pages 部署
  - 響應式設計 (RWD + Bootstrap)
  - 資料視覺化整合

- **系統整合與維運**
  - R Server 雙向同步
  - 備份與災難復原
  - Gemini CLI 提升效率

## 🚀 快速開始

### 準備工作
1. 建立 GitHub 帳號
2. 安裝 Git 或 GitHub Desktop
3. 準備 R/RStudio 環境

### 課程實作
```bash
# 1. 建立第一個 Repository
gh repo create my-forecast-model --public

# 2. 初始化本地專案
git clone https://github.com/username/my-forecast-model
cd my-forecast-model

# 3. 建立基本檔案結構
mkdir -p data-processed metadata code .github/workflows
touch README.md

# 4. 提交初始版本
git add .
git commit -m "初始化預測模型專案"
git push
```

## 🎓 學習資源

### 📖 延伸閱讀
- [GitHub Docs](https://docs.github.com)
- [GitHub Actions 官方文件](https://docs.github.com/actions)
- [Bootstrap 中文文件](https://bootstrap5.hexschool.com/)
- [Quarto 官方指南](https://quarto.org/docs/guide/)


## 💡 核心概念速查

### Git 常用指令
```bash
git init                    # 初始化倉庫
git add .                   # 暫存所有變更
git commit -m "訊息"        # 提交版本
git push                    # 推送到遠端
git status                  # 查看狀態
git log --oneline          # 查看歷史
```

### GitHub Actions 基本結構
```yaml
name: 工作流程名稱
on: [push, pull_request]    # 觸發條件
jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: 執行步驟
      run: echo "Hello World"
```

### Bootstrap 響應式網格
```html
<div class="container">
  <div class="row">
    <div class="col-md-6">左半邊</div>
    <div class="col-md-6">右半邊</div>
  </div>
</div>
```

## 🔧 技術規格

### 系統需求
- **Git**: 2.0+ 
- **Node.js**: 16+ (GitHub Actions)
- **R**: 4.0+ (資料處理)
- **瀏覽器**: Chrome 90+ / Firefox 88+ / Safari 14+

### GitHub 免費方案額度
- **Public Repositories**: 無限制
- **Private Repositories**: 無限制 (2GB 儲存)
- **GitHub Actions**: 2,000 分鐘/月
- **GitHub Pages**: 1GB 空間，100GB 流量/月

