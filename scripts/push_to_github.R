# R Server 推送資料到 GitHub 的腳本

library(git2r)
library(tidyverse)
library(keyring)

# 安全地取得 GitHub Token
get_github_token <- function() {
  # 嘗試從 keyring 取得
  tryCatch({
    return(key_get("github_pat"))
  }, error = function(e) {
    # 如果沒有設定，提示使用者
    cat("請先設定 GitHub Personal Access Token:\n")
    cat("key_set('github_pat')\n")
    stop("未設定 GitHub 認證")
  })
}

# 處理監測資料 (示例函數)
process_weekly_data <- function() {
  # 這裡應該是實際的資料處理邏輯
  # 示例：產生模擬資料
  data.frame(
    date = seq(Sys.Date() - 6, Sys.Date(), by = "day"),
    cases = round(rnorm(7, mean = 100, sd = 20)),
    region = "Taiwan"
  )
}

# 主要推送函數
push_surveillance_data <- function(repo_path = "/home/rserver/github/data-repository") {
  
  cat("開始推送監測資料到 GitHub...\n")
  
  # 檢查 repo 路徑是否存在
  if (!dir.exists(repo_path)) {
    stop("Repository 路徑不存在: ", repo_path)
  }
  
  # 初始化 repository 物件
  repo <- repository(repo_path)
  
  # 處理監測資料
  surveillance_data <- process_weekly_data()
  
  # 產生時間戳記
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- sprintf("surveillance_%s.csv", timestamp)
  data_path <- file.path(repo_path, "data", filename)
  
  # 確保 data 目錄存在
  dir.create(file.path(repo_path, "data"), showWarnings = FALSE, recursive = TRUE)
  
  # 寫入檔案
  write_csv(surveillance_data, data_path)
  
  # 建立 commit 資訊
  author_sig <- signature("R Server", "rserver@cdc.gov.tw")
  commit_msg <- paste("Auto update:", timestamp)
  
  # Git 操作
  tryCatch({
    # 暫存檔案
    add(repo, path = paste0("data/", filename))
    
    # 提交變更
    commit(repo, message = commit_msg, author = author_sig)
    
    # 推送 (使用 token 認證)
    token <- get_github_token()
    Sys.setenv(GITHUB_PAT = token)
    creds <- cred_token()
    push(repo, credentials = creds)
    
    cat("✅ 資料已成功推送:", filename, "\n")
    
  }, error = function(e) {
    cat("❌ 推送失敗:", e$message, "\n")
    stop(e)
  })
}

# 設定定期推送
setup_scheduled_push <- function() {
  library(cronR)
  
  # 建立排程任務
  script_path <- system.file("scripts/push_to_github.R", package = getwd())
  log_path <- "/home/rserver/logs/github_push.log"
  
  cmd <- cron_rscript(
    rscript = script_path,
    rscript_log = log_path,
    log_append = TRUE
  )
  
  # 每日早上 8 點執行
  cron_add(
    command = cmd,
    frequency = "daily",
    at = "08:00",
    id = "github_push",
    description = "每日推送資料到 GitHub"
  )
  
  cat("✅ 已設定每日自動推送排程\n")
  cat("檢視排程: cron_ls()\n")
}

# 記錄 GitHub 活動
log_github_activity <- function(action, details) {
  log_entry <- data.frame(
    timestamp = Sys.time(),
    action = action,
    details = details,
    user = Sys.info()["user"],
    stringsAsFactors = FALSE
  )
  
  log_file <- "/home/rserver/logs/github_activity.csv"
  
  # 如果檔案不存在，建立標題行
  if (!file.exists(log_file)) {
    dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)
    write_csv(log_entry, log_file)
  } else {
    write_csv(log_entry, log_file, append = TRUE)
  }
}

# 主執行區塊
if (!interactive()) {
  # 記錄開始
  log_github_activity("push_start", "開始推送監測資料")
  
  # 執行推送
  tryCatch({
    push_surveillance_data()
    log_github_activity("push_success", "推送成功")
  }, error = function(e) {
    log_github_activity("push_error", paste("推送失敗:", e$message))
    stop(e)
  })
}