#!/bin/bash
set -euo pipefail
BLOG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ "$(uname -s)" = Darwin ] || { printf '此安装脚本用于 macOS。\n' >&2; exit 1; }
git --version >/dev/null
mkdir -p "$BLOG_ROOT/.tools" "$BLOG_ROOT/.deploy"
if [ ! -x "$BLOG_ROOT/.tools/hugo" ]; then
  BLOG_TEMP="$(mktemp -d "${TMPDIR:-/tmp/}remy-hugo.XXXXXX")"
  trap 'rm -rf "$BLOG_TEMP"' EXIT
  BLOG_ASSET=hugo_extended_0.157.0_darwin-universal.pkg
  BLOG_RELEASE=https://github.com/gohugoio/hugo/releases/download/v0.157.0
  curl --fail --show-error --location "$BLOG_RELEASE/$BLOG_ASSET" -o "$BLOG_TEMP/$BLOG_ASSET"
  curl --fail --show-error --location "$BLOG_RELEASE/hugo_0.157.0_checksums.txt" -o "$BLOG_TEMP/checksums.txt"
  (cd "$BLOG_TEMP" && awk -v asset="$BLOG_ASSET" '$2 == asset {print}' checksums.txt > selected.sha256 && \
    test -s selected.sha256 && shasum -a 256 -c selected.sha256)
  pkgutil --expand-full "$BLOG_TEMP/$BLOG_ASSET" "$BLOG_TEMP/package"
  cp "$BLOG_TEMP/package/Payload/hugo" "$BLOG_ROOT/.tools/hugo"
  chmod +x "$BLOG_ROOT/.tools/hugo"
fi
"$BLOG_ROOT/.tools/hugo" version
if [ ! -d "$BLOG_ROOT/.deploy/pages/.git" ]; then
  git clone https://github.com/RemyWang22/RemyWang22.github.io.git "$BLOG_ROOT/.deploy/pages"
fi
for BLOG_REPO in "$BLOG_ROOT" "$BLOG_ROOT/.deploy/pages"; do
  if ! git -C "$BLOG_REPO" config user.name >/dev/null; then
    git -C "$BLOG_REPO" config --local user.name "$(git -C "$BLOG_ROOT" log -1 --format=%an)"
  fi
  if ! git -C "$BLOG_REPO" config user.email >/dev/null; then
    git -C "$BLOG_REPO" config --local user.email "$(git -C "$BLOG_ROOT" log -1 --format=%ae)"
  fi
done
bash "$BLOG_ROOT/scripts/build.sh"
printf '\nMac 本地环境已就绪。预览：bash "%s/scripts/preview.sh"\n' "$BLOG_ROOT"

