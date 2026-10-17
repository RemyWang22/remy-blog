#!/bin/bash
set -euo pipefail
BLOG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -x "$BLOG_ROOT/.tools/gh" ]; then
  printf '缺少 GitHub CLI，请先运行 scripts/install-github-cli.sh。\n' >&2
  exit 1
fi
export GH_CONFIG_DIR="$BLOG_ROOT/.tools/github"
export GIT_CONFIG_GLOBAL="$BLOG_ROOT/.tools/gitconfig"
mkdir -p "$GH_CONFIG_DIR"
if ! "$BLOG_ROOT/.tools/gh" auth status --hostname github.com >/dev/null 2>&1; then
  "$BLOG_ROOT/.tools/gh" auth login --hostname github.com --git-protocol https --web --skip-ssh-key
fi
BLOG_ACCOUNT="$("$BLOG_ROOT/.tools/gh" api user --jq .login)"
case "$BLOG_ACCOUNT" in
  RemyWang22|remywang22) ;;
  *) printf '当前登录的是 %s；本项目需要 RemyWang22。请切换账号后重试。\n' "$BLOG_ACCOUNT" >&2; exit 1 ;;
esac
for BLOG_REPO in "$BLOG_ROOT" "$BLOG_ROOT/.deploy/pages"; do
  git -C "$BLOG_REPO" config --local --replace-all credential.https://github.com.helper ''
  git -C "$BLOG_REPO" config --local --add credential.https://github.com.helper "!\"$BLOG_ROOT/scripts/github-credential.sh\""
done
printf '\nGitHub 账号已连接：%s。现在可以使用“发布博客.command”。\n' "$BLOG_ACCOUNT"
