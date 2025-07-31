#!/bin/bash
# 災難復原腳本

set -e  # 遇到錯誤立即停止

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日誌函數
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 檢查必要工具
check_prerequisites() {
    log "檢查必要工具..."
    
    local tools=("git" "gh" "curl" "tar")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool 未安裝"
            exit 1
        fi
    done
    
    success "所有必要工具已安裝"
}

# 檢查 GitHub 認證
check_github_auth() {
    log "檢查 GitHub 認證..."
    
    if ! gh auth status &> /dev/null; then
        error "GitHub CLI 未認證，請執行: gh auth login"
        exit 1
    fi
    
    success "GitHub 認證有效"
}

# 列出可用的備份
list_available_backups() {
    log "列出可用的備份..."
    
    echo "1. GitHub Artifacts (最近 30 天)"
    gh api repos/cdc-modeling-hub/backup/actions/artifacts --jq '.artifacts[] | select(.name | contains("backup")) | "\(.name) - \(.created_at)"' | head -10
    
    echo -e "\n2. GitHub Releases (週備份)"
    gh api repos/cdc-modeling-hub/backup/releases --jq '.[] | select(.tag_name | contains("backup")) | "\(.tag_name) - \(.published_at)"' | head -5
}

# 下載指定備份
download_backup() {
    local backup_name="$1"
    local download_dir="recovery_$(date +%Y%m%d_%H%M%S)"
    
    log "下載備份: $backup_name"
    mkdir -p "$download_dir"
    
    # 嘗試從 Artifacts 下載
    if gh run download -n "$backup_name" -D "$download_dir" 2>/dev/null; then
        success "從 Artifacts 下載成功"
        echo "$download_dir"
        return 0
    fi
    
    # 嘗試從 Releases 下載
    if gh release download "$backup_name" -D "$download_dir" 2>/dev/null; then
        success "從 Releases 下載成功"
        echo "$download_dir"
        return 0
    fi
    
    error "無法下載備份: $backup_name"
    rm -rf "$download_dir"
    return 1
}

# 還原 Repository
restore_repository() {
    local backup_file="$1"
    local repo_name="$2"
    
    log "還原 Repository: $repo_name"
    
    if [[ ! -f "$backup_file" ]]; then
        error "備份檔案不存在: $backup_file"
        return 1
    fi
    
    # 解壓備份
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # 找到 .git 目錄
    local git_dir=$(find "$temp_dir" -name "*.git" -type d | head -1)
    
    if [[ -z "$git_dir" ]]; then
        error "備份中沒有找到 Git 資料"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 從備份復原
    local restore_dir="${repo_name}-restored"
    git clone "$git_dir" "$restore_dir"
    
    success "Repository 已復原到: $restore_dir"
    
    # 清理臨時檔案
    rm -rf "$temp_dir"
    
    echo "$restore_dir"
}

# 驗證復原的 Repository
verify_restored_repo() {
    local repo_dir="$1"
    
    log "驗證復原的 Repository: $repo_dir"
    
    if [[ ! -d "$repo_dir" ]]; then
        error "復原目錄不存在: $repo_dir"
        return 1
    fi
    
    cd "$repo_dir"
    
    # 檢查 Git 歷史
    local commit_count=$(git rev-list --count HEAD)
    log "Commit 數量: $commit_count"
    
    # 檢查重要檔案
    local important_files=("README.md" ".github/workflows" "data-processed")
    local missing_files=()
    
    for file in "${important_files[@]}"; do
        if [[ ! -e "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        warning "缺少重要檔案: ${missing_files[*]}"
    fi
    
    # 檢查最新 commit
    log "最新 commit:"
    git log --oneline -5
    
    success "Repository 驗證完成"
    cd - > /dev/null
}

# 復原已刪除的 Repository
restore_deleted_repo() {
    local repo_name="$1"
    
    log "嘗試復原已刪除的 Repository: $repo_name"
    
    # 使用 GitHub API 復原
    if gh api "repos/cdc-modeling-hub/$repo_name/restore" -X POST 2>/dev/null; then
        success "Repository $repo_name 已成功復原"
        return 0
    else
        error "無法復原 Repository $repo_name (可能超過 90 天限制)"
        return 1
    fi
}

# 主選單
show_menu() {
    echo "=================================="
    echo "    災難復原工具"
    echo "=================================="
    echo "1. 列出可用備份"
    echo "2. 從備份復原 Repository"
    echo "3. 復原已刪除的 Repository"
    echo "4. 驗證復原結果"
    echo "5. 完整系統復原"
    echo "0. 退出"
    echo "=================================="
}

# 完整系統復原
full_system_recovery() {
    log "開始完整系統復原..."
    
    # 1. 列出備份
    list_available_backups
    
    echo -e "\n請輸入要復原的備份名稱:"
    read -r backup_name
    
    if [[ -z "$backup_name" ]]; then
        error "請輸入備份名稱"
        return 1
    fi
    
    # 2. 下載備份
    download_dir=$(download_backup "$backup_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # 3. 復原所有 Repository
    log "復原所有 Repository..."
    
    local backup_files=($(find "$download_dir" -name "*.tar.gz"))
    local restored_repos=()
    
    for backup_file in "${backup_files[@]}"; do
        local repo_name=$(basename "$backup_file" .tar.gz | sed 's/_[0-9]*$//')
        
        restored_dir=$(restore_repository "$backup_file" "$repo_name")
        if [[ $? -eq 0 ]]; then
            restored_repos+=("$restored_dir")
        fi
    done
    
    # 4. 驗證所有復原結果
    log "驗證復原結果..."
    
    for repo_dir in "${restored_repos[@]}"; do
        verify_restored_repo "$repo_dir"
    done
    
    success "完整系統復原完成！"
    log "復原的 Repository: ${restored_repos[*]}"
}

# 主程式
main() {
    log "災難復原程序啟動"
    
    # 檢查前置條件
    check_prerequisites
    check_github_auth
    
    while true; do
        show_menu
        read -p "請選擇操作 (0-5): " choice
        
        case $choice in
            1)
                list_available_backups
                ;;
            2)
                echo "請輸入備份名稱:"
                read -r backup_name
                download_dir=$(download_backup "$backup_name")
                
                if [[ $? -eq 0 ]]; then
                    echo "請輸入要復原的 Repository 名稱:"
                    read -r repo_name
                    
                    # 尋找對應的備份檔案
                    backup_file=$(find "$download_dir" -name "*${repo_name}*.tar.gz" | head -1)
                    
                    if [[ -n "$backup_file" ]]; then
                        restore_repository "$backup_file" "$repo_name"
                    else
                        error "找不到 $repo_name 的備份檔案"
                    fi
                fi
                ;;
            3)
                echo "請輸入要復原的 Repository 名稱:"
                read -r repo_name
                restore_deleted_repo "$repo_name"
                ;;
            4)
                echo "請輸入要驗證的 Repository 目錄:"
                read -r repo_dir
                verify_restored_repo "$repo_dir"
                ;;
            5)
                full_system_recovery
                ;;
            0)
                log "程式結束"
                exit 0
                ;;
            *)
                warning "無效選項，請重新選擇"
                ;;
        esac
        
        echo -e "\n按 Enter 繼續..."
        read
    done
}

# 執行主程式
main "$@"