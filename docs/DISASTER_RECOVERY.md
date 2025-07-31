# 災難復原手冊

## 緊急聯絡人

- **主要負責人**: 王經理 (0912-345-678)
- **技術負責人**: 李工程師 (0923-456-789)  
- **GitHub 管理員**: 陳組長 (0934-567-890)

## 快速復原指令

### 情境 1: 誤刪檔案

```bash
# 查看檔案刪除歷史
git log --name-status --follow -- <file-path>

# 復原到特定版本
git checkout <commit-hash> -- <file-path>

# 或復原到上一個版本
git checkout HEAD~1 -- <file-path>
```

### 情境 2: 誤刪 Repository

1. **GitHub 網頁操作**:
   - 登入 GitHub
   - 進入 Settings → Repositories → Deleted repositories
   - 找到誤刪的 Repository
   - 點擊 "Restore" 按鈕

2. **CLI 操作**:
   ```bash
   # 復原已刪除的 Repository
   gh api repos/cdc-modeling-hub/DELETED_REPO/restore -X POST
   ```

### 情境 3: 從備份完整復原

```bash
# 下載最新備份
gh release download backup-20250729

# 解壓復原
tar xzf repo-name_backup.tar.gz
cd repo-name.git
git clone . ../repo-name-new

# 推送到新 Repository
cd ../repo-name-new
git remote set-url origin https://github.com/cdc-modeling-hub/repo-name-restored.git
git push -u origin main
```

## 備份位置

### 1. GitHub Artifacts
- **保存期限**: 30 天
- **存取方式**: GitHub Actions → Artifacts
- **適用場景**: 短期復原需求

### 2. GitHub Releases  
- **保存期限**: 永久 (每週備份)
- **存取方式**: Repository → Releases
- **適用場景**: 長期復原需求

### 3. 外部備份 (選用)
- **Google Drive**: `cdc-github-backups/`
- **保存期限**: 依設定
- **存取方式**: rclone 或網頁介面

## 復原程序 SOP

### 階段 1: 評估災難範圍

1. **確認受影響範圍**
   ```bash
   # 檢查 Organization 狀態
   gh org list cdc-modeling-hub
   
   # 列出所有 Repository
   gh repo list cdc-modeling-hub --limit 100
   ```

2. **記錄災難詳情**
   - 發生時間
   - 影響範圍  
   - 可能原因
   - 立即採取的行動

### 階段 2: 啟動復原程序

1. **通知相關人員**
   ```bash
   # 發送緊急通知 (需設定 Slack/Teams webhook)
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"🚨 GitHub 災難復原程序啟動"}' \
     $SLACK_WEBHOOK_URL
   ```

2. **執行自動復原腳本**
   ```bash
   # 啟動災難復原工具
   ./scripts/disaster_recovery.sh
   ```

### 階段 3: 資料復原

1. **選擇適當的備份**
   ```bash
   # 列出可用備份
   gh release list --repo cdc-modeling-hub/backup
   
   # 選擇最接近災難發生前的備份
   gh release download backup-20250729
   ```

2. **執行批次復原**
   ```bash
   # 批次復原所有 Repository
   for backup in *.tar.gz; do
     repo_name=$(basename "$backup" .tar.gz)
     echo "復原 $repo_name"
     
     # 解壓並復原
     tar xzf "$backup"
     cd "${repo_name}.git"
     git clone . "../${repo_name}-restored"
     cd ..
   done
   ```

### 階段 4: 驗證復原結果

1. **檢查 Repository 完整性**
   ```bash
   for repo in *-restored; do
     echo "檢查 $repo"
     cd "$repo"
     
     # 檢查 commit 歷史
     git log --oneline -10
     
     # 檢查重要檔案
     ls -la data-processed/ metadata/ 2>/dev/null || echo "目錄缺失"
     
     cd ..
   done
   ```

2. **測試自動化流程**
   ```bash
   # 測試 GitHub Actions
   gh workflow run validate-submission.yml
   
   # 檢查執行結果
   gh run list --limit 5
   ```

### 階段 5: 復原後處理

1. **更新權限設定**
   ```bash
   # 重新設定團隊權限
   gh api orgs/cdc-modeling-hub/teams/maintainers/repos/cdc-modeling-hub/repo-name \
     -f permission=maintain -X PUT
   ```

2. **通知復原完成**
   ```bash
   # 發送完成通知
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"✅ GitHub 災難復原完成"}' \
     $SLACK_WEBHOOK_URL
   ```

## 預防措施

### 定期備份檢查

```bash
# 每週執行的備份驗證腳本
#!/bin/bash
echo "檢查備份狀態..."

# 檢查最近 7 天的備份
for i in {0..6}; do
  date=$(date -d "$i days ago" +%Y%m%d)
  
  if gh release view "backup-$date" >/dev/null 2>&1; then
    echo "✅ $date 備份存在"
  else
    echo "❌ $date 備份缺失"
  fi
done
```

### 權限審查

```bash
# 每月權限審查腳本
#!/bin/bash
echo "=== 權限審查報告 ==="

# 列出所有管理員
echo "Organization 管理員:"
gh api orgs/cdc-modeling-hub/members --jq '.[].login'

# 列出所有 Repository 協作者
echo -e "\nRepository 協作者:"
gh repo list cdc-modeling-hub --limit 100 --json name | \
  jq -r '.[].name' | \
  while read repo; do
    echo "Repository: $repo"
    gh api repos/cdc-modeling-hub/$repo/collaborators --jq '.[].login'
    echo
  done
```

## 測試復原程序

### 每季演練

1. **選擇測試 Repository**
   ```bash
   # 建立測試用 Repository
   gh repo create cdc-modeling-hub/disaster-recovery-test --public
   
   # 加入測試資料
   echo "Test data" > test-file.txt
   git add test-file.txt
   git commit -m "Add test data"
   git push
   ```

2. **執行模擬災難**
   ```bash
   # 刪除檔案 (模擬意外刪除)
   git rm test-file.txt
   git commit -m "Simulate accidental deletion"
   git push
   ```

3. **測試復原程序**
   ```bash
   # 使用復原程序還原檔案
   git checkout HEAD~1 -- test-file.txt
   git add test-file.txt
   git commit -m "Restore deleted file"
   git push
   ```

4. **記錄測試結果**
   - 復原所需時間
   - 發現的問題
   - 改進建議

## 聯絡資訊更新

當聯絡資訊變更時，請更新以下位置：

1. **本文件** (`DISASTER_RECOVERY.md`)
2. **緊急聯絡清單** (`docs/emergency_contacts.json`)
3. **自動通知設定** (GitHub Secrets)
4. **團隊共享文件**

## 復原後檢討

每次災難復原後都應進行檢討會議：

### 檢討重點
- 災難發生原因
- 復原程序效果
- 響應時間分析
- 預防措施改進

### 文件更新
- 更新復原程序
- 修正發現的問題
- 加強預防措施
- 更新訓練材料

---

**重要提醒**: 
- 定期更新此文件
- 確保所有相關人員熟悉程序
- 定期進行復原演練
- 保持備份系統正常運作

*最後更新: 2025-07-30*