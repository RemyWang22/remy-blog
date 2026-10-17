#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
mkdir -p "$BLOG_ROOT/.build/cache"
printf '浏览器打开 http://localhost:1313/ 即可预览。按 Control+C 停止。\n'
exec "$BLOG_HUGO" server --source "$BLOG_ROOT" --buildDrafts \
  --destination "$BLOG_ROOT/.build/preview" \
  --bind 127.0.0.1 --port 1313 --cacheDir "$BLOG_ROOT/.build/cache" \
  --baseURL http://localhost:1313/ --appendPort=false
