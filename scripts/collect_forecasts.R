# 收集所有預測資料的腳本 (用於網站建置)

library(tidyverse)
library(gh)

# 取得所有預測 repositories
get_forecast_repos <- function() {
  repos <- gh("GET /orgs/{org}/repos",
              org = "cdc-modeling-hub",
              type = "all",
              per_page = 100)
  
  # 篩選預測 repos
  forecast_repos <- repos %>%
    keep(~ str_detect(.x$name, "^forecast-"))
  
  return(forecast_repos)
}

# 收集各 repo 的預測資料
collect_all_forecasts <- function() {
  cat("開始收集預測資料...\n")
  
  forecast_repos <- get_forecast_repos()
  cat("找到", length(forecast_repos), "個預測 repositories\n")
  
  all_forecasts <- map_dfr(forecast_repos, function(repo) {
    cat("處理 repository:", repo$name, "\n")
    
    tryCatch({
      # 取得 data-processed 目錄的檔案列表
      files <- gh("GET /repos/{owner}/{repo}/contents/{path}",
                  owner = "cdc-modeling-hub",
                  repo = repo$name,
                  path = "data-processed")
      
      # 篩選 CSV 檔案
      csv_files <- keep(files, ~ str_detect(.x$name, "\\.csv$"))
      
      if (length(csv_files) == 0) {
        cat("  沒有找到 CSV 檔案\n")
        return(NULL)
      }
      
      # 讀取每個 CSV 檔案
      repo_data <- map_dfr(csv_files, function(file) {
        cat("  讀取檔案:", file$name, "\n")
        
        # 下載檔案內容
        content <- gh("GET /repos/{owner}/{repo}/contents/{path}",
                      owner = "cdc-modeling-hub",
                      repo = repo$name,
                      path = file.path("data-processed", file$name))
        
        # 解碼 Base64 內容
        raw_content <- base64enc::base64decode(content$content)
        temp_file <- tempfile(fileext = ".csv")
        writeBin(raw_content, temp_file)
        
        # 讀取 CSV
        data <- read_csv(temp_file, show_col_types = FALSE)
        
        # 加入來源資訊
        data$repository <- repo$name
        data$file_name <- file$name
        data$last_modified <- content$commit$committer$date
        
        return(data)
      })
      
      return(repo_data)
      
    }, error = function(e) {
      cat("  錯誤:", e$message, "\n")
      return(NULL)
    })
  })
  
  if (!is.null(all_forecasts) && nrow(all_forecasts) > 0) {
    cat("✅ 總共收集了", nrow(all_forecasts), "筆預測資料\n")
    
    # 儲存整合資料
    dir.create("data", showWarnings = FALSE)
    write_csv(all_forecasts, "data/latest_forecasts.csv")
    
    # 產生摘要統計
    summary_stats <- all_forecasts %>%
      group_by(repository) %>%
      summarise(
        record_count = n(),
        date_range = paste(min(forecast_date, na.rm = TRUE), 
                          "to", 
                          max(forecast_date, na.rm = TRUE)),
        last_update = max(as.Date(last_modified), na.rm = TRUE),
        .groups = "drop"
      )
    
    write_csv(summary_stats, "data/forecast_summary.csv")
    cat("✅ 摘要統計已儲存\n")
    
  } else {
    cat("❌ 沒有收集到任何資料\n")
  }
  
  return(all_forecasts)
}

# 產生模型效能資料 (示例)
generate_model_performance <- function(forecast_data) {
  if (is.null(forecast_data) || nrow(forecast_data) == 0) {
    return(NULL)
  }
  
  cat("產生模型效能統計...\n")
  
  # 示例：計算每個模型的統計
  model_stats <- forecast_data %>%
    # 從 repository 名稱提取團隊資訊
    mutate(
      team = str_extract(repository, "(?<=forecast-\\d{4}-W\\d{2}-).*"),
      week = str_extract(repository, "W\\d{2}")
    ) %>%
    filter(type == "point") %>%
    group_by(team, week) %>%
    summarise(
      submission_count = n(),
      avg_prediction = mean(value, na.rm = TRUE),
      prediction_range = max(value, na.rm = TRUE) - min(value, na.rm = TRUE),
      locations_covered = n_distinct(location),
      .groups = "drop"
    ) %>%
    # 計算簡單的分數 (示例)
    mutate(
      Score = round(pmin(100, pmax(0, 100 - (prediction_range / avg_prediction * 50))), 1),
      MAE = round(rnorm(n(), 15, 5), 2),  # 示例數據
      RMSE = round(rnorm(n(), 20, 7), 2)  # 示例數據
    )
  
  write_csv(model_stats, "data/model_performance.csv")
  cat("✅ 模型效能資料已產生\n")
  
  return(model_stats)
}

# 主執行函數
main <- function() {
  cat("=== 開始收集預測資料 ===\n")
  cat("時間:", format(Sys.time()), "\n")
  
  # 收集所有預測資料
  all_forecasts <- collect_all_forecasts()
  
  # 產生模型效能統計
  model_performance <- generate_model_performance(all_forecasts)
  
  cat("=== 資料收集完成 ===\n")
}

# 如果直接執行此腳本
if (!interactive()) {
  main()
}