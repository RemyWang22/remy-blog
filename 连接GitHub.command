#!/bin/bash
BLOG_ROOT="$(cd "$(dirname "$0")" && pwd)"
if [ ! -x "$BLOG_ROOT/.tools/gh" ]; then
  bash "$BLOG_ROOT/scripts/install-github-cli.sh" || exit $?
fi
bash "$BLOG_ROOT/scripts/connect-github.sh"
BLOG_STATUS=$?
printf '\n按回车关闭窗口。\n'
read -r
exit "$BLOG_STATUS"
