#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
mkdir -p "$BLOG_ROOT/.build/site" "$BLOG_ROOT/.build/cache"
"$BLOG_HUGO" --source "$BLOG_ROOT" --destination "$BLOG_ROOT/.build/site" \
  --cacheDir "$BLOG_ROOT/.build/cache" --minify --cleanDestinationDir
touch "$BLOG_ROOT/.build/site/.nojekyll"
printf '\n构建完成：%s/.build/site\n' "$BLOG_ROOT"

