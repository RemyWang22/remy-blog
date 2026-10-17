#!/bin/bash
set -euo pipefail
BLOG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export GH_CONFIG_DIR="$BLOG_ROOT/.tools/github"
exec "$BLOG_ROOT/.tools/gh" auth git-credential "$@"

