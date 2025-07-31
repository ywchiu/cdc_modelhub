# 執行所有檢查的主要腳本

library(tidyverse)

# 載入驗證函數
source("validation/validate_forecast.R")

# 執行所有檢查
run_all_checks <- function() {
  cat("開始執行完整驗證流程...\n")
  
  errors <- c()
  warnings <- c()
  
  # 檢查目錄結構
  required_dirs <- c("data-processed", "metadata", "code")
  for (dir in required_dirs) {
    if (!dir.exists(dir)) {
      errors <- c(errors, paste("缺少必要目錄:", dir))
    }
  }
  
  if (length(errors) > 0) {
    stop(paste(errors, collapse = "\n"))
  }
  
  # 執行資料驗證
  tryCatch({
    validate_all()
  }, error = function(e) {
    errors <- c(errors, paste("資料驗證失敗:", e$message))
  }, warning = function(w) {
    warnings <- c(warnings, paste("資料驗證警告:", w$message))
  })
  
  # 檢查檔案命名規範
  csv_files <- list.files("data-processed", pattern = "\\.csv$", recursive = TRUE)
  for (file in csv_files) {
    if (!grepl("^\\d{4}-\\d{2}-\\d{2}-.+\\.csv$", basename(file))) {
      warnings <- c(warnings, paste("檔案命名不符規範:", file))
    }
  }
  
  # 輸出結果
  if (length(errors) > 0) {
    cat("❌ 發現錯誤:\n")
    cat(paste(errors, collapse = "\n"), "\n")
    stop("驗證失敗")
  }
  
  if (length(warnings) > 0) {
    cat("⚠️ 發現警告:\n")
    cat(paste(warnings, collapse = "\n"), "\n")
  }
  
  cat("✅ 所有檢查通過！\n")
  return(TRUE)
}

# 執行檢查
if (!interactive()) {
  run_all_checks()
}