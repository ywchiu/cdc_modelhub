#!/bin/bash

# 設定 PAT
export GIT_ASKPASS="git-credential.sh"

git add data/*
git commit -m "Auto commit $(date '+%Y-%m-%d %H:%M')"
git push origin main
