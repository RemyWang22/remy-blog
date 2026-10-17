#!/bin/bash
set -euo pipefail
BLOG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "$(uname -m)" in
  arm64) BLOG_ARCH=arm64 ;;
  x86_64) BLOG_ARCH=amd64 ;;
  *) printf '不支持此 Mac 架构。\n' >&2; exit 1 ;;
esac
BLOG_TEMP="$(mktemp -d "${TMPDIR:-/tmp/}remy-gh.XXXXXX")"
trap 'rm -rf "$BLOG_TEMP"' EXIT
BLOG_ASSET="gh_2.102.0_macOS_${BLOG_ARCH}.zip"
BLOG_RELEASE=https://github.com/cli/cli/releases/download/v2.102.0
curl --fail --show-error --location "$BLOG_RELEASE/$BLOG_ASSET" -o "$BLOG_TEMP/$BLOG_ASSET"
curl --fail --show-error --location "$BLOG_RELEASE/gh_2.102.0_checksums.txt" -o "$BLOG_TEMP/checksums.txt"
(cd "$BLOG_TEMP" && awk -v asset="$BLOG_ASSET" '$2 == asset {print}' checksums.txt > selected.sha256 && \
  test -s selected.sha256 && shasum -a 256 -c selected.sha256)
ditto -x -k "$BLOG_TEMP/$BLOG_ASSET" "$BLOG_TEMP/unpacked"
mkdir -p "$BLOG_ROOT/.tools"
cp "$BLOG_TEMP/unpacked/gh_2.102.0_macOS_${BLOG_ARCH}/bin/gh" "$BLOG_ROOT/.tools/gh"
chmod +x "$BLOG_ROOT/.tools/gh"
"$BLOG_ROOT/.tools/gh" --version

