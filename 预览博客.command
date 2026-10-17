#!/bin/bash
BLOG_ROOT="$(cd "$(dirname "$0")" && pwd)"
bash "$BLOG_ROOT/scripts/preview.sh"
BLOG_STATUS=$?
if [ "$BLOG_STATUS" -ne 0 ] && [ "$BLOG_STATUS" -ne 130 ]; then
  printf '\n预览未能启动。按回车关闭窗口。\n'
  read -r
fi
exit "$BLOG_STATUS"

