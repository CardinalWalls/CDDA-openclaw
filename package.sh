#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_NAME="cdda-live-demo"
VERSION="0.1.0"

cd "$SCRIPT_DIR"

echo "=== 打包 CDDA Live Demo ==="

# 清理
rm -rf "dist/$PKG_NAME-$VERSION"
mkdir -p "dist"

# 复制所有文件
cp -R "$PKG_NAME" "dist/$PKG_NAME-$VERSION"

# 打包
cd dist
tar -czvf "$PKG_NAME-$VERSION.tar.gz" "$PKG_NAME-$VERSION"
zip -r "$PKG_NAME-$VERSION.zip" "$PKG_NAME-$VERSION"
cd ..

echo ""
echo "=== 打包完成 ==="
ls -lh "dist/$PKG_NAME-$VERSION.tar.gz" "dist/$PKG_NAME-$VERSION.zip"

echo ""
echo "分发方式:"
echo "1. 上传 dist/$PKG_NAME-$VERSION.tar.gz 到 GitHub Release"
echo "2. 或直接共享整个 cdda-live-demo 目录"
