#!/usr/bin/env bash
set -euo pipefail

# Build a distributable ZIP for WordPress.org from the current directory.
# It respects .distignore to exclude development files.

PLUGIN_SLUG="nr-post-exporter"
BUILD_DIR=".build/${PLUGIN_SLUG}"

rm -rf .build
mkdir -p "${BUILD_DIR}"

# Sync files while excluding from .distignore if present
# Sync files while excluding from .distignore if present
if [[ -f .distignore ]]; then
  rsync -av --delete --exclude-from=.distignore ./ "${BUILD_DIR}/"
else
  rsync -av --delete ./ "${BUILD_DIR}/" --exclude ".build" --exclude "build" --exclude ".git" --exclude "node_modules" --exclude "vendor"
fi

# Always exclude test directory from the distributable
rm -rf "${BUILD_DIR}/test"

mkdir -p dist
cd .build
zip -r "../dist/${PLUGIN_SLUG}.zip" "${PLUGIN_SLUG}" >/dev/null
cd ..

echo "Built dist/${PLUGIN_SLUG}.zip"
