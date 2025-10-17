---
aliases: 
tags: 
date_modified: 
date: 2025-10-7
---

# GitHub分支管理

## 公司机器创建dev分支

```bash
cd /Users/zhanghui/codex/mysql-sea-syncweb

git checkout -b dev
git push -u origin dev
```


## 公司机器在dev分支上开发

```bash
# 分支切换
git checkout dev
git pull origin dev  # 确保获取最新代码

# 开发流程
# 在dev分支上进行功能开发

# 定期提交代码
git add . && git commit -m "功能描述"

# 定期推送
git push origin dev
```


## 家里机器在dev分支上开发

```bash
# 首次同步
git fetch origin
git checkout dev
git pull origin dev

# 定期提交代码
git add . && git commit -m "功能描述"

# 定期推送
git push origin dev

# 注意在dev分支下git push只推送当前分支
git push

# 注意在dev分支下git pull只拉取当前分支
git pull
```


## 为什么要定期合并main分支到dev分支

- main分支通常包含稳定的、经过测试的代码
- 如果main分支有bug修复、安全更新或重要功能，dev分支需要及时获取这些更新
- 避免dev分支与main分支差异过大，导致最终合并时出现大量冲突

## 如何合并main分支到dev分支

```bash
# 检查当前分支状态
git status

# 确保在dev分支上
git checkout dev

# 拉取最新的main分支代码
git fetch origin
git checkout main
git pull origin main

# 切换回dev分支
git checkout dev

# 合并main分支到dev分支
git merge main

# 推送更新后的dev分支
git push origin dev
```


## 如何处理冲突

```bash
# 检查当前分支状态
git status

# 查看main分支的更新
git log main..origin/main

# 查看dev分支的更新
git log origin/main..dev

# 查看冲突文件
git status

# 手动解决冲突后
git add <解决冲突的文件>

# 完成合并
git commit

# 推送更新
git push origin dev
```


## 合并dev分支到main

### 家里机器

```bash
# 第一阶段：推送dev分支到远程
# 1. 确保dev分支最新更改已推送
git add .
git commit -m "清理项目：删除测试脚本、调试文件、备份文件和临时文件"
git push origin dev

# 第二阶段：合并dev到main
# 2. 切换到main分支
git checkout main

# 3. 拉取最新的main分支
git pull origin main

# 4. 合并dev分支到main（建议使用--no-ff保留合并历史）
git merge --no-ff dev -m "合并dev分支"

# 5. 推送合并后的main分支
git push origin main

# 第三阶段：创建重构分支
# 6. 基于最新main创建重构分支
git checkout -b refactor

# 7. 推送新分支到远程
git push -u origin refactor

# 8. 确认分支创建成功
git branch -a

# 第四阶段：验证分支状态
# 9. 查看分支关系
git log --oneline --graph --all -10

# 10. 确认当前在重构分支
git status
```

### 公司机器

```bash
# 第一阶段：同步远程更改
# 1. 拉取所有远程分支更新
git fetch --all

# 2. 查看远程分支状态
git branch -a

# 3. 切换到main分支并更新
git checkout main
git pull origin main

# 4. 更新dev分支（如果需要）
git checkout dev
git pull origin dev

# 第二阶段：获取重构分支
# 5. 切换到新的重构分支
git checkout refactor

# 6. 确认分支内容正确
git log --oneline -5
git status

# 第三阶段：验证环境一致性
# 7. 确认核心文件存在
ls -la *.py | head -10

# 8. 确认配置文件
ls -la executor_configs/
```


## 强制拉取远程分支到本地

```bash
# 从远程获取最新分支数据
git fetch origin

# 强制把当前分支重置为远程origin/main的状态，本地未提交修改会被清空
git reset --hard origin/main
```


## 强制推送本地分支到远程

```bash
# 强制推送本地mdev分支内容并覆盖远程
git push origin dev --force
```


## 强制删除分支

```bash
# 删除本地refactor分支
git branch -D refactor

# 删除远程refactor分支
git push origin --delete refactor
```


## 用main分支覆盖dev分支

```bash
# 确保在main分支
git checkout main

# 强制将main的内容写入dev分支
git branch -f dev

# 切换到dev并继续开发
git checkout dev

# 可选：强制推送dev到远程
git push origin dev --force
```