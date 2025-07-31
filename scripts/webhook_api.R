# GitHub Webhook 接收端 API (使用 plumber)

library(plumber)
library(jsonlite)
library(openssl)

# 驗證 Webhook 簽章的函數
verify_webhook <- function(payload, signature, secret) {
  if (is.null(signature) || is.null(secret)) {
    return(FALSE)
  }
  
  # 計算 HMAC
  expected <- openssl::sha256(
    charToRaw(payload),
    key = charToRaw(secret)
  )
  
  # 比較簽章
  provided <- gsub("sha256=", "", signature)
  
  identical(as.character(expected), provided)
}

# 記錄 Webhook 事件
log_webhook_event <- function(event_type, payload_summary) {
  log_entry <- data.frame(
    timestamp = Sys.time(),
    event_type = event_type,
    summary = payload_summary,
    stringsAsFactors = FALSE
  )
  
  log_file <- "/home/rserver/logs/webhook_events.csv"
  
  if (!file.exists(log_file)) {
    dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)
    write_csv(log_entry, log_file)
  } else {
    write_csv(log_entry, log_file, append = TRUE)
  }
}

# 處理推送事件
handle_push_event <- function(payload) {
  repo_name <- payload$repository$name
  branch <- basename(payload$ref)
  
  cat("收到推送事件 - Repository:", repo_name, "Branch:", branch, "\n")
  
  # 如果是預測資料推送，觸發分析
  if (grepl("^forecast-", repo_name) && branch == "main") {
    cat("觸發預測分析...\n")
    
    # 這裡可以呼叫分析腳本
    tryCatch({
      source("/home/rserver/scripts/run_analysis.R")
      run_analysis(repo_name)
      
      log_webhook_event("analysis_triggered", 
                       paste("Analysis for", repo_name))
      
    }, error = function(e) {
      cat("分析執行失敗:", e$message, "\n")
      log_webhook_event("analysis_error", 
                       paste("Error in", repo_name, ":", e$message))
    })
  }
}

# 處理 Pull Request 事件
handle_pr_event <- function(payload) {
  action <- payload$action
  pr_number <- payload$number
  repo_name <- payload$repository$name
  
  cat("收到 PR 事件 - Action:", action, "PR:", pr_number, "\n")
  
  if (action == "opened") {
    # 新 PR 開啟，可以觸發自動檢查
    log_webhook_event("pull_request_opened", 
                     paste("PR", pr_number, "in", repo_name))
  }
}

#* @post /webhook
function(req) {
  # 取得 Webhook 密鑰 (應該設定在環境變數)
  webhook_secret <- Sys.getenv("GITHUB_WEBHOOK_SECRET")
  
  # 驗證來源
  signature <- req$HTTP_X_HUB_SIGNATURE_256
  
  if (webhook_secret != "" && !verify_webhook(req$postBody, signature, webhook_secret)) {
    cat("Webhook 驗證失敗\n")
    return(list(error = "Unauthorized", status = 401))
  }
  
  # 解析事件
  payload <- tryCatch({
    fromJSON(req$postBody)
  }, error = function(e) {
    cat("無法解析 JSON payload:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(payload)) {
    return(list(error = "Invalid JSON", status = 400))
  }
  
  event_type <- req$HTTP_X_GITHUB_EVENT
  
  # 處理不同事件類型
  tryCatch({
    if (event_type == "push") {
      handle_push_event(payload)
    } else if (event_type == "pull_request") {
      handle_pr_event(payload)
    } else {
      cat("未處理的事件類型:", event_type, "\n")
    }
    
    return(list(status = "success", message = "Event processed"))
    
  }, error = function(e) {
    cat("處理事件時發生錯誤:", e$message, "\n")
    return(list(error = e$message, status = 500))
  })
}

#* @get /health
function() {
  list(
    status = "healthy",
    timestamp = Sys.time(),
    version = "1.0.0"
  )
}

#* @get /logs
function() {
  log_file <- "/home/rserver/logs/webhook_events.csv"
  
  if (file.exists(log_file)) {
    logs <- read_csv(log_file)
    return(tail(logs, 10))  # 回傳最後 10 筆記錄
  } else {
    return(list(message = "No logs found"))
  }
}

# 啟動 API 的函數
start_webhook_server <- function(host = "0.0.0.0", port = 8000) {
  cat("啟動 Webhook 伺服器於", paste0(host, ":", port), "\n")
  cat("健康檢查: http://", host, ":", port, "/health\n", sep = "")
  cat("Webhook 端點: http://", host, ":", port, "/webhook\n", sep = "")
  
  pr <- plumb(system.file("api.R", package = getwd()))
  pr$run(host = host, port = port)
}

# 如果直接執行此腳本
if (!interactive()) {
  start_webhook_server()
}