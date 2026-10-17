#!/usr/bin/env bash
# macOS 自带的 Bash 3.2 可运行。只使用正常推送，保留两边的 Git 历史。
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
PAGES="$ROOT/.deploy/pages"
SITE="$ROOT/.build/site"
STEP="检查参数"
SOURCE_COMMITTED=0
SOURCE_PUSHED=0
PAGES_SYNCED=0
PAGES_COMMITTED=0
PAGES_PUSHED=0

die() {
    printf '错误：%s\n' "$*" >&2
    exit 1
}

report_exit() {
    result=$?
    if [ "$result" -ne 0 ]; then
        printf '\n发布未完成，出错步骤：%s。当前文件和已有提交均已保留。\n' "$STEP" >&2
        if [ "$SOURCE_COMMITTED" -eq 1 ]; then
            printf '源码本地提交已创建。\n' >&2
        fi
        if [ "$SOURCE_PUSHED" -eq 1 ]; then
            printf '源码已推送到 GitHub。\n' >&2
        fi
        if [ "$PAGES_SYNCED" -eq 1 ] && [ "$PAGES_COMMITTED" -eq 0 ]; then
            printf 'Pages 目录已同步，可能有尚未提交的改动；请先检查该目录的 Git 状态和差异。\n' >&2
        fi
        if [ "$PAGES_COMMITTED" -eq 1 ] && [ "$PAGES_PUSHED" -eq 0 ]; then
            printf 'Pages 本地提交已创建，但尚未确认推送成功；可修复问题后重新运行。\n' >&2
        fi
        if [ "$SOURCE_COMMITTED" -eq 1 ] && [ "$SOURCE_PUSHED" -eq 0 ]; then
            printf '源码提交尚未确认推送成功；可修复问题后重新运行。\n' >&2
        fi
    fi
}
trap report_exit EXIT

usage() {
    printf '用法：bash scripts/publish.sh "本次更新备注"\n'
    printf '      bash scripts/publish.sh --check\n'
    printf '不提供备注时，会在终端中提示输入。--check 仅执行离线构建和检查。\n'
}

CHECK_ONLY=0
MESSAGE=""
case "${1:-}" in
    --check)
        [ "$#" -eq 1 ] || die '--check 不能同时传入更新备注。'
        CHECK_ONLY=1
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    --*) die '未知选项。请使用 --check、--help 或直接提供更新备注。' ;;
    *)
        if [ "$#" -gt 0 ]; then
            MESSAGE="$*"
        elif [ -t 0 ]; then
            printf '请输入本次更新的备注：'
            IFS= read -r MESSAGE || die '未读取到更新备注。'
        else
            die '请将非空更新备注作为参数传入，或在终端中运行。'
        fi
        case "$MESSAGE" in
            *[![:space:]]*) ;;
            *) die '更新备注不能为空。' ;;
        esac
        ;;
esac

require_repo() {
    repo=$1
    label=$2
    top=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) || die "$label 仓库不存在或尚未完成克隆。"
    [ "$top" = "$repo" ] || die "$label 路径不是独立仓库的根目录。"
    branch=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null) || die "$label 仓库当前未处于分支上。"
    [ "$branch" = main ] || die "$label 仓库必须处于 main 分支。"
    [ -z "$(git -C "$repo" ls-files --unmerged)" ] || die "$label 仓库有未解决的合并冲突。"
    for state in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
        state_path=$(git -C "$repo" rev-parse --git-path "$state")
        case "$state_path" in /*) ;; *) state_path="$repo/$state_path" ;; esac
        [ ! -e "$state_path" ] || die "$label 仓库有尚未完成的 Git 操作。"
    done
}

validate_origin() {
    repo=$1
    expected=$2
    label=$3
    for kind in fetch push; do
        if [ "$kind" = push ]; then
            urls=$(git -C "$repo" remote get-url --all --push origin 2>/dev/null) || die "$label 缺少 origin 推送地址。"
        else
            urls=$(git -C "$repo" remote get-url --all origin 2>/dev/null) || die "$label 缺少 origin 地址。"
        fi
        [ -n "$urls" ] || die "$label 的 origin 地址为空。"
        while IFS= read -r url; do
            normalized=$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')
            case "$normalized" in
                "https://github.com/remywang22/$expected"|"https://github.com/remywang22/$expected.git"|\
                "https://github.com/remywang22/$expected/"|"https://github.com/remywang22/$expected.git/"|\
                "git@github.com:remywang22/$expected"|"git@github.com:remywang22/$expected.git"|\
                "ssh://git@github.com/remywang22/$expected"|"ssh://git@github.com/remywang22/$expected.git") ;;
                *) die "$label 的 origin 与预期 GitHub 仓库不符，请先检查远端配置。" ;;
            esac
        done <<< "$urls"
    done
}

require_identity() {
    repo=$1
    label=$2
    name=$(git -C "$repo" config --get user.name || true)
    email=$(git -C "$repo" config --get user.email || true)
    case "$name" in *[![:space:]]*) ;; *) die "$label 尚未设置 Git user.name。" ;; esac
    case "$email" in *[![:space:]]*) ;; *) die "$label 尚未设置 Git user.email。" ;; esac
    git -C "$repo" var GIT_AUTHOR_IDENT >/dev/null 2>&1 || die "$label 的 Git 作者信息无效。"
    git -C "$repo" var GIT_COMMITTER_IDENT >/dev/null 2>&1 || die "$label 的 Git 提交者信息无效。"
}

require_clean_pages() {
    [ -z "$(git -C "$PAGES" status --porcelain --ignored --untracked-files=all)" ] || die 'Pages 仓库有未提交的改动或被忽略的本地文件，请先检查并处理，避免覆盖已有工作。'
}

fetch_main() {
    repo=$1
    label=$2
    GIT_TERMINAL_PROMPT=0 git -C "$repo" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main >/dev/null 2>&1 || die "$label 拉取失败，请检查网络、GitHub 登录和远端 main 分支。"
}

check_push_access() {
    repo=$1
    label=$2
    # 隐去认证输出，避免凭据或认证助手输出出现在终端。
    GIT_TERMINAL_PROMPT=0 git -C "$repo" push --dry-run origin HEAD:refs/heads/main >/dev/null 2>&1 || die "$label 推送权限检查失败，请先完成 GitHub 认证并确认 main 可推送。"
}

push_main() {
    repo=$1
    label=$2
    GIT_TERMINAL_PROMPT=0 git -C "$repo" push origin HEAD:refs/heads/main >/dev/null 2>&1 || die "$label 推送失败。请检查网络和远端更新；本地提交已保留。"
}

STEP="检查仓库和构建配置"
command -v git >/dev/null 2>&1 || die '未找到 Git。'
command -v rsync >/dev/null 2>&1 || die '未找到 rsync。'
require_repo "$ROOT" '源码'
require_repo "$PAGES" 'Pages'
validate_origin "$ROOT" remy-blog '源码'
validate_origin "$PAGES" remywang22.github.io 'Pages'
[ -f "$ROOT/scripts/build.sh" ] || die '缺少 scripts/build.sh。'
# 在暂存源码前确认构建输出和独立 Pages 克隆不会进入源码提交。
git -C "$ROOT" check-ignore -q .build/site/index.html || die '请先将 .build/ 加入源码仓库的 .gitignore。'
git -C "$ROOT" check-ignore -q .deploy/pages || die '请先将 .deploy/ 加入源码仓库的 .gitignore。'
git -C "$ROOT" check-ignore -q .tools/github/hosts.yml || die '请先将 .tools/ 加入源码仓库的 .gitignore，避免提交运行工具或 GitHub 凭据。'
[ -z "$(git -C "$ROOT" ls-files -- .build .deploy .tools)" ] || die '源码仓库已跟踪 .build、.deploy 或 .tools 文件，请先检查并处理。'

STEP="构建网站"
(cd "$ROOT" && bash "$ROOT/scripts/build.sh")
[ -s "$SITE/index.html" ] || die '构建产物缺少非空 index.html。'
[ -f "$SITE/.nojekyll" ] || die '构建产物缺少 .nojekyll。'
site_real=$(CDPATH= cd -- "$SITE" && pwd -P)
[ "$site_real" = "$SITE" ] || die '构建输出目录不能是指向其他位置的符号链接。'

if [ "$CHECK_ONLY" -eq 1 ]; then
    printf '离线检查通过：网站已构建，两个仓库的 main 分支和 origin 配置正确。未拉取、暂存、提交或推送。\n'
    exit 0
fi

STEP="检查 Git 身份和 Pages 工作区"
require_identity "$ROOT" '源码'
require_identity "$PAGES" 'Pages'
require_clean_pages

STEP="拉取远端并检查分支"
fetch_main "$ROOT" '源码'
fetch_main "$PAGES" 'Pages'
if git -C "$PAGES" merge-base --is-ancestor HEAD origin/main; then
    git -C "$PAGES" merge --ff-only origin/main >/dev/null 2>&1 || die 'Pages 无法进行快进更新。'
elif ! git -C "$PAGES" merge-base --is-ancestor origin/main HEAD; then
    die 'Pages 的本地 main 与远端已分叉，请保留现有工作并先处理分支差异。'
fi
require_clean_pages
git -C "$ROOT" merge-base --is-ancestor origin/main HEAD || die '源码 main 落后于远端或已分叉，请保留改动并先处理远端更新。'

STEP="检查两个仓库的推送权限"
check_push_access "$ROOT" '源码'
check_push_access "$PAGES" 'Pages'

STEP="提交源码"
git -C "$ROOT" add -A -- .
if git -C "$ROOT" diff --cached --quiet; then
    printf '源码内容未变化，跳过提交。\n'
else
    git -C "$ROOT" commit -m "$MESSAGE"
    SOURCE_COMMITTED=1
fi
STEP="推送源码"
push_main "$ROOT" '源码'
SOURCE_PUSHED=1

STEP="同步 Pages 构建产物"
# clean main 已验证；排除项同时保护 .git 和现有自定义域名 CNAME 免于删除。
require_repo "$PAGES" 'Pages'
validate_origin "$PAGES" remywang22.github.io 'Pages'
require_clean_pages
PAGES_SYNCED=1
rsync -a --delete --exclude='/.git' --exclude='/CNAME' --exclude='.DS_Store' "$SITE/" "$PAGES/" || die '同步构建产物失败，请检查 Pages 目录中的差异。'

STEP="提交 Pages"
git -C "$PAGES" add -A -- .
if git -C "$PAGES" diff --cached --quiet; then
    printf 'Pages 内容未变化，跳过提交。\n'
else
    git -C "$PAGES" commit -m "$MESSAGE"
    PAGES_COMMITTED=1
fi
STEP="推送 Pages"
push_main "$PAGES" 'Pages'
PAGES_PUSHED=1
printf '\n发布完成：源码和 Pages 均已推送。GitHub Pages 随后会更新网站。\n'
printf 'https://remywang22.github.io/\n'
