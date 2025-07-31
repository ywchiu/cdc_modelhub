# 備份關鍵資料的腳本

library(tidyverse)
library(jsonlite)

# 備份關鍵資料
backup_critical <- function(backup_dir = NULL) {
  
  if (is.null(backup_dir)) {
    backup_dir <- paste0("critical_backup_", Sys.Date())
  }
  
  cat("開始備份關鍵資料到:", backup_dir, "\n")
  
  # 建立備份目錄
  dir.create(backup_dir, showWarnings = FALSE, recursive = TRUE)
  
  # 建立備份清單
  critical_files <- c(
    "data/historical_forecasts.csv",
    "data/model_scores.csv", 
    "data/latest_forecasts.csv",
    "data/model_performance.csv",
    "config/team_contacts.json",
    "validation/validate_forecast.R",
    "scripts/collect_forecasts.R"
  )
  
  # 檢查並複製檔案
  backed_up_files <- c()
  missing_files <- c()
  
  for (file_path in critical_files) {
    if (file.exists(file_path)) {
      # 建立相對目錄結構
      dest_dir <- file.path(backup_dir, dirname(file_path))
      dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
      
      dest_file <- file.path(backup_dir, file_path)
      
      # 複製檔案
      file.copy(file_path, dest_file, overwrite = TRUE)
      
      # 計算 MD5 確保完整性
      if (file.exists(dest_file)) {
        md5_hash <- tools::md5sum(file_path)
        writeLines(as.character(md5_hash), paste0(dest_file, ".md5"))
        
        backed_up_files <- c(backed_up_files, file_path)
        cat("✅ 已備份:", file_path, "\n")
      } else {
        cat("❌ 備份失敗:", file_path, "\n")
      }
    } else {
      missing_files <- c(missing_files, file_path)
      cat("⚠️ 檔案不存在:", file_path, "\n")
    }
  }
  
  # 產生備份清單
  backup_manifest <- list(
    backup_date = Sys.time(),
    backed_up_files = backed_up_files,
    missing_files = missing_files,
    total_files = length(critical_files),
    success_count = length(backed_up_files),
    backup_directory = backup_dir
  )
  
  # 儲存備份清單
  writeLines(toJSON(backup_manifest, pretty = TRUE), 
             file.path(backup_dir, "backup_manifest.json"))
  
  # 產生備份報告
  report <- c(
    paste("備份完成時間:", format(Sys.time())),
    paste("備份目錄:", backup_dir),
    paste("成功備份檔案:", length(backed_up_files), "/", length(critical_files)),
    "",
    "成功備份的檔案:",
    paste("  ✅", backed_up_files),
    "",
    if (length(missing_files) > 0) {
      c("缺失的檔案:",
        paste("  ⚠️", missing_files))
    } else {
      "所有檔案都已成功備份"
    }
  )
  
  writeLines(report, file.path(backup_dir, "backup_report.txt"))
  
  cat("\n=== 備份完成 ===\n")
  cat("備份目錄:", backup_dir, "\n")
  cat("成功備份:", length(backed_up_files), "個檔案\n")
  
  if (length(missing_files) > 0) {
    cat("警告: 有", length(missing_files), "個檔案缺失\n")
  }
  
  return(backup_manifest)
}

# 驗證備份完整性
verify_backup <- function(backup_dir) {
  cat("驗證備份完整性:", backup_dir, "\n")
  
  manifest_file <- file.path(backup_dir, "backup_manifest.json")
  
  if (!file.exists(manifest_file)) {
    stop("找不到備份清單檔案")
  }
  
  manifest <- fromJSON(manifest_file)
  
  all_valid <- TRUE
  
  for (file_path in manifest$backed_up_files) {
    backup_file <- file.path(backup_dir, file_path)
    md5_file <- paste0(backup_file, ".md5")
    
    if (file.exists(backup_file) && file.exists(md5_file)) {
      # 檢查 MD5
      current_md5 <- tools::md5sum(backup_file)
      stored_md5 <- readLines(md5_file)[1]
      
      if (as.character(current_md5) == stored_md5) {
        cat("✅", file_path, "完整性驗證通過\n")
      } else {
        cat("❌", file_path, "MD5 不符，檔案可能損壞\n")
        all_valid <- FALSE
      }
    } else {
      cat("❌", file_path, "備份檔案或 MD5 檔案缺失\n")
      all_valid <- FALSE
    }
  }
  
  if (all_valid) {
    cat("✅ 所有備份檔案完整性驗證通過\n")
  } else {
    cat("❌ 發現備份檔案問題\n")
  }
  
  return(all_valid)
}

# 還原備份
restore_backup <- function(backup_dir, target_dir = ".") {
  cat("從備份還原檔案:", backup_dir, "到", target_dir, "\n")
  
  manifest_file <- file.path(backup_dir, "backup_manifest.json")
  
  if (!file.exists(manifest_file)) {
    stop("找不到備份清單檔案")
  }
  
  # 先驗證備份完整性
  if (!verify_backup(backup_dir)) {
    warning("備份完整性驗證失敗，但繼續還原")
  }
  
  manifest <- fromJSON(manifest_file)
  
  restored_files <- c()
  
  for (file_path in manifest$backed_up_files) {
    backup_file <- file.path(backup_dir, file_path)
    target_file <- file.path(target_dir, file_path)
    
    if (file.exists(backup_file)) {
      # 建立目標目錄
      dir.create(dirname(target_file), showWarnings = FALSE, recursive = TRUE)
      
      # 還原檔案
      if (file.copy(backup_file, target_file, overwrite = TRUE)) {
        cat("✅ 還原:", file_path, "\n")
        restored_files <- c(restored_files, file_path)
      } else {
        cat("❌ 還原失敗:", file_path, "\n")
      }
    } else {
      cat("❌ 備份檔案不存在:", file_path, "\n")
    }
  }
  
  cat("✅ 還原完成，成功還原", length(restored_files), "個檔案\n")
  return(restored_files)
}

# 清理舊備份
cleanup_old_backups <- function(backup_base_dir = "./backups", days_to_keep = 30) {
  cat("清理", days_to_keep, "天前的舊備份...\n")
  
  if (!dir.exists(backup_base_dir)) {
    cat("備份目錄不存在:", backup_base_dir, "\n")
    return(invisible())
  }
  
  backup_dirs <- list.dirs(backup_base_dir, full.names = TRUE, recursive = FALSE)
  
  cutoff_date <- Sys.Date() - days_to_keep
  removed_count <- 0
  
  for (backup_dir in backup_dirs) {
    # 從目錄名稱提取日期
    dir_name <- basename(backup_dir)
    
    if (grepl("critical_backup_\\d{4}-\\d{2}-\\d{2}", dir_name)) {
      date_str <- str_extract(dir_name, "\\d{4}-\\d{2}-\\d{2}")
      backup_date <- as.Date(date_str)
      
      if (!is.na(backup_date) && backup_date < cutoff_date) {
        cat("刪除舊備份:", backup_dir, "\n")
        unlink(backup_dir, recursive = TRUE)
        removed_count <- removed_count + 1
      }
    }
  }
  
  cat("✅ 清理完成，刪除了", removed_count, "個舊備份\n")
}

# 主執行函數
main <- function() {
  cat("=== 關鍵資料備份程序 ===\n")
  
  # 執行備份
  backup_manifest <- backup_critical()
  
  # 驗證備份
  verify_backup(backup_manifest$backup_directory)
  
  # 清理舊備份
  cleanup_old_backups()
  
  cat("=== 備份程序完成 ===\n")
}

# 如果直接執行此腳本
if (!interactive()) {
  main()
}