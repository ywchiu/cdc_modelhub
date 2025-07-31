#!/bin/bash
# Git 基礎操作示範腳本

echo "=== Git 基礎操作示範 ==="

# 1. 初始化新專案
echo "步驟 1: 初始化新專案"
mkdir -p my-forecast-model
cd my-forecast-model

# 初始化 Git 倉庫
git init
echo "Initialized empty Git repository"

# 2. 新增檔案並追蹤
echo -e "\n步驟 2: 新增檔案並追蹤"
echo "COVID-19 預測模型 v1.0" > forecast.R

# 檢查狀態
echo -e "\n檢查 Git 狀態:"
git status

# 3. 暫存與提交
echo -e "\n步驟 3: 暫存與提交"
# 暫存檔案
git add forecast.R

# 提交版本
git commit -m "初始版本：基礎預測模型"

# 4. 建立新分支進行改進
echo -e "\n步驟 4: 建立新分支進行改進"
git checkout -b feature/add-weather

# 修改檔案
echo "# 加入氣象資料的 SEIR 模型" >> forecast.R
echo "weather_data <- load_weather()" >> forecast.R
echo "cases_predicted <- seir_model(data, weather_data)" >> forecast.R

# 提交改進
git add forecast.R
git commit -m "加入氣象資料功能"

# 切回主分支並合併
git checkout main
git merge feature/add-weather

echo -e "\n=== 操作完成 ==="
echo "所有基礎 Git 操作已完成展示"

# 常用 Git 指令參考
echo -e "\n=== 常用 Git 指令參考 ==="
echo "git init              # 初始化倉庫"
echo "git status            # 查看狀態"
echo "git add .             # 暫存所有檔案"
echo "git commit -m '訊息'  # 提交版本"
echo "git log --oneline     # 查看歷史"
echo "git checkout <branch> # 切換分支"
echo "git merge <branch>    # 合併分支"