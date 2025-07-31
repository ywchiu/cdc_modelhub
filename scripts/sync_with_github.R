# 雙向同步 GitHub 資料的腳本

library(tidyverse)
library(gh)
library(git2r)

# 設定 GitHub 認證
setup_github_auth <- function() {
  token <- Sys.getenv("GITHUB_PAT")
  if (token == "") {
    # 嘗試從 keyring 取得
    tryCatch({
      token <- keyring::key_get("github_pat")
      Sys.setenv(GITHUB_PAT = token)
    }, error = function(e) {
      stop("請設定 GITHUB_PAT 環境變數或使用 keyring::key_set('github_pat')")
    })
  }
}

# 列出所有預測 repositories
list_forecast_repos <- function() {
  setup_github_auth()
  
  repos <- gh("GET /orgs/{org}/repos",
              org = "cdc-modeling-hub",
              type = "all",
              per_page = 100)
  
  # 篩選預測 repos
  forecast_repos <- keep(repos, 
                        ~ grepl("^forecast-", .x$name))
  
  map_chr(forecast_repos, "name")
}

# 下載特定檔案
download_forecast <- function(repo_name, file_path) {
  setup_github_auth()
  
  content <- gh("GET /repos/{owner}/{repo}/contents/{path}",
                owner = "cdc-modeling-hub",
                repo = repo_name,
                path = file_path)
  
  # Base64 解碼
  raw_content <- base64enc::base64decode(content$content)
  temp_file <- tempfile(fileext = ".csv")
  writeBin(raw_content, temp_file)
  
  read_csv(temp_file, show_col_types = FALSE)
}

# 從 GitHub 拉取最新資料
pull_from_github <- function(local_repo_path = "./local_repo") {
  if (!dir.exists(local_repo_path)) {
    cat("本地 repository 不存在，請先 clone\n")
    return(FALSE)
  }
  
  repo <- repository(local_repo_path)
  
  # 拉取更新
  setup_github_auth()
  fetch(repo, credentials = cred_token())
  
  # 檢查是否有更新
  local_sha <- sha(repository_head(repo))
  
  tryCatch({
    merge(repo, "origin/main")
    
    new_sha <- sha(repository_head(repo))
    
    if (local_sha != new_sha) {
      cat("✅ 發現新的更新，已合併\n")
      return(TRUE)
    } else {
      cat("📄 沒有新的更新\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("❌ 合併失敗:", e$message, "\n")
    return(FALSE)
  })
}

# 處理新預測資料
process_new_forecasts <- function(repo_path = "./local_repo") {
  cat("處理新的預測資料...\n")
  
  # 尋找新的 CSV 檔案
  csv_files <- list.files(
    file.path(repo_path, "data-processed"),
    pattern = "\\.csv$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  all_forecasts <- data.frame()
  
  for (file in csv_files) {
    tryCatch({
      forecast_data <- read_csv(file, show_col_types = FALSE)
      forecast_data$source_file <- basename(file)
      all_forecasts <- bind_rows(all_forecasts, forecast_data)
    }, error = function(e) {
      cat("無法讀取檔案", file, ":", e$message, "\n")
    })
  }
  
  if (nrow(all_forecasts) > 0) {
    cat("處理了", nrow(all_forecasts), "筆預測資料\n")
    return(all_forecasts)
  } else {
    cat("沒有找到有效的預測資料\n")
    return(NULL)
  }
}

# 執行集成分析 (示例)
run_ensemble_analysis <- function(forecast_data = NULL) {
  if (is.null(forecast_data)) {
    cat("沒有資料可供分析\n")
    return(NULL)
  }
  
  cat("執行集成分析...\n")
  
  # 簡單的集成方法 - 計算平均值
  ensemble_results <- forecast_data %>%
    filter(type == "point") %>%
    group_by(forecast_date, target, target_end_date, location) %>%
    summarise(
      ensemble_value = mean(value, na.rm = TRUE),
      model_count = n(),
      .groups = "drop"
    ) %>%
    mutate(
      type = "point",
      quantile = NA_real_,
      model = "ensemble"
    )
  
  cat("✅ 集成分析完成，產生", nrow(ensemble_results), "筆結果\n")
  return(ensemble_results)
}

# 推送結果回 GitHub
push_results_to_github <- function(results, repo_path = "./local_repo") {
  if (is.null(results) || nrow(results) == 0) {
    cat("沒有結果可推送\n")
    return(FALSE)
  }
  
  repo <- repository(repo_path)
  
  # 儲存結果
  results_dir <- file.path(repo_path, "analysis")
  dir.create(results_dir, showWarnings = FALSE)
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  results_file <- file.path(results_dir, paste0("ensemble_results_", timestamp, ".csv"))
  
  write_csv(results, results_file)
  
  # Git 操作
  tryCatch({
    add(repo, paste0("analysis/ensemble_results_", timestamp, ".csv"))
    
    commit(repo, 
           message = paste("Update ensemble analysis", timestamp),
           author = signature("R Server", "rserver@cdc.gov.tw"))
    
    setup_github_auth()
    push(repo, credentials = cred_token())
    
    cat("✅ 結果已推送到 GitHub\n")
    return(TRUE)
    
  }, error = function(e) {
    cat("❌ 推送失敗:", e$message, "\n")
    return(FALSE)
  })
}

# 主同步函數
sync_cycle <- function(repo_path = "./local_repo") {
  cat("開始同步週期...\n")
  cat("時間:", format(Sys.time()), "\n")
  
  # 1. 從 GitHub 拉取更新
  has_updates <- pull_from_github(repo_path)
  
  if (has_updates) {
    # 2. 處理新資料
    forecast_data <- process_new_forecasts(repo_path)
    
    # 3. 執行分析
    results <- run_ensemble_analysis(forecast_data)
    
    # 4. 推送結果
    push_results_to_github(results, repo_path)
  }
  
  cat("✅ 同步週期完成\n")
  cat("下次同步時間:", format(Sys.time() + 3600), "\n")  # 1小時後
}

# 設定定期同步
setup_sync_schedule <- function() {
  library(cronR)
  
  script_path <- system.file("scripts/sync_with_github.R", package = getwd())
  log_path <- "/home/rserver/logs/github_sync.log"
  
  cmd <- cron_rscript(
    rscript = script_path,
    rscript_log = log_path,
    log_append = TRUE
  )
  
  # 每小時執行一次
  cron_add(
    command = cmd,
    frequency = "hourly",
    id = "github_sync",
    description = "每小時同步 GitHub 資料"
  )
  
  cat("✅ 已設定每小時同步排程\n")
}

# 主執行區塊
if (!interactive()) {
  # 執行一次同步週期
  sync_cycle()
}