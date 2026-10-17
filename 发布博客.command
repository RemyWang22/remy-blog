#!/bin/bash
BLOG_ROOT="$(cd "$(dirname "$0")" && pwd)"
bash "$BLOG_ROOT/scripts/publish.sh"
BLOG_STATUS=$?
printf '\n按回车关闭窗口。\n'
read -r
exit "$BLOG_STATUS"
