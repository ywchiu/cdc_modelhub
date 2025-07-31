# 預測資料驗證腳本
# 用於驗證提交的預測檔案格式與內容

library(tidyverse)
library(yaml)

# 主要驗證函數
validate_forecast <- function(file_path) {
  cat("驗證檔案:", basename(file_path), "\n")
  
  # 檢查檔案是否存在
  if (!file.exists(file_path)) {
    stop("檔案不存在: ", file_path)
  }
  
  # 讀取預測檔案
  tryCatch({
    data <- read.csv(file_path)
  }, error = function(e) {
    stop("無法讀取 CSV 檔案: ", e$message)
  })
  
  # 檢查必要欄位
  required_cols <- c("forecast_date", "target", 
                    "target_end_date", "location", 
                    "type", "quantile", "value")
  
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(paste("缺少必要欄位:", 
               paste(missing_cols, collapse = ", ")))
  }
  
  # 檢查日期格式
  dates <- as.Date(data$forecast_date, "%Y-%m-%d")
  if (any(is.na(dates))) {
    stop("日期格式錯誤，應為 YYYY-MM-DD")
  }
  
  # 檢查目標日期格式
  target_dates <- as.Date(data$target_end_date, "%Y-%m-%d")
  if (any(is.na(target_dates))) {
    stop("目標日期格式錯誤，應為 YYYY-MM-DD")
  }
  
  # 檢查預測值是否為數值
  if (!is.numeric(data$value)) {
    stop("預測值必須為數值")
  }
  
  # 檢查預測值是否為負數
  if (any(data$value < 0, na.rm = TRUE)) {
    warning("發現負數預測值，請確認是否正確")
  }
  
  # 檢查 quantile 欄位
  valid_quantiles <- c(NA, 0.025, 0.25, 0.5, 0.75, 0.975)
  invalid_quantiles <- setdiff(unique(data$quantile), valid_quantiles)
  if (length(invalid_quantiles) > 0) {
    stop("無效的 quantile 值: ", paste(invalid_quantiles, collapse = ", "))
  }
  
  # 檢查 type 欄位
  valid_types <- c("point", "quantile")
  invalid_types <- setdiff(unique(data$type), valid_types)
  if (length(invalid_types) > 0) {
    stop("無效的 type 值: ", paste(invalid_types, collapse = ", "))
  }
  
  cat("✓ 格式驗證通過\n")
  return(TRUE)
}

# 驗證 metadata 檔案
validate_metadata <- function(file_path) {
  cat("驗證 metadata:", basename(file_path), "\n")
  
  if (!file.exists(file_path)) {
    stop("Metadata 檔案不存在: ", file_path)
  }
  
  # 讀取 YAML
  tryCatch({
    meta <- read_yaml(file_path)
  }, error = function(e) {
    stop("無法讀取 YAML 檔案: ", e$message)
  })
  
  # 檢查必要欄位
  required_fields <- c("team_name", "model_name", 
                      "methods", "data_inputs")
  missing_fields <- setdiff(required_fields, names(meta))
  
  if (length(missing_fields) > 0) {
    stop(paste("Metadata 缺少必要欄位:", 
              paste(missing_fields, collapse = ", ")))
  }
  
  cat("✓ Metadata 驗證通過\n")
  return(TRUE)
}

# 批次驗證函數
validate_all <- function(data_dir = "data-processed", meta_dir = "metadata") {
  cat("=== 開始批次驗證 ===\n")
  
  # 驗證所有 CSV 檔案
  if (dir.exists(data_dir)) {
    csv_files <- list.files(data_dir, 
                           pattern = "\\.csv$", 
                           recursive = TRUE, 
                           full.names = TRUE)
    
    if (length(csv_files) == 0) {
      warning("在 ", data_dir, " 中沒有找到 CSV 檔案")
    } else {
      cat("找到", length(csv_files), "個預測檔案\n")
      for (file in csv_files) {
        validate_forecast(file)
      }
    }
  }
  
  # 驗證所有 YAML 檔案
  if (dir.exists(meta_dir)) {
    yaml_files <- list.files(meta_dir, 
                            pattern = "\\.ya?ml$", 
                            full.names = TRUE)
    
    if (length(yaml_files) == 0) {
      warning("在 ", meta_dir, " 中沒有找到 YAML 檔案")
    } else {
      cat("找到", length(yaml_files), "個 metadata 檔案\n")
      for (file in yaml_files) {
        validate_metadata(file)
      }
    }
  }
  
  cat("=== 所有驗證完成 ===\n")
}

# 如果直接執行此腳本
if (!interactive()) {
  # 執行批次驗證
  validate_all()
}