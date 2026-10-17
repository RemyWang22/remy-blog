#!/bin/bash
set -euo pipefail

BLOG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOG_HUGO="$BLOG_ROOT/.tools/hugo"
if [ ! -x "$BLOG_HUGO" ]; then
  printf '缺少 Hugo。请先运行：bash "%s/scripts/setup-mac.sh"\n' "$BLOG_ROOT" >&2
  exit 1
fi
case "$("$BLOG_HUGO" version)" in
  *'v0.157.0'*) ;;
  *) printf '本项目需要 Hugo 0.157.0，请重新运行 setup-mac.sh。\n' >&2; exit 1 ;;
esac

