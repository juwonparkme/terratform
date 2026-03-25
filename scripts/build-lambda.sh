#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
APP_ZIP="${DIST_DIR}/lambda-app.zip"
LAYER_ZIP="${DIST_DIR}/lambda-layer.zip"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/deeplx-proxy-build.XXXXXX")"
APP_BUILD_DIR="${TMP_ROOT}/app"
LAYER_BUILD_DIR="${TMP_ROOT}/layer"
PYTHON_BIN="${PYTHON_BIN:-python3}"

cleanup() {
  if command -v trash >/dev/null 2>&1; then
    trash "${TMP_ROOT}" >/dev/null 2>&1 || true
  else
    rm -rf "${TMP_ROOT}"
  fi
}

trap cleanup EXIT

PYTHON_VERSION="${LAMBDA_PYTHON_VERSION:-3.12}"
PYTHON_ABI="${LAMBDA_PYTHON_ABI:-cp${PYTHON_VERSION/./}}"
PLATFORM_TAG="${LAMBDA_PLATFORM_TAG:-manylinux2014_x86_64}"

mkdir -p "${DIST_DIR}" "${APP_BUILD_DIR}" "${LAYER_BUILD_DIR}/python"

if command -v trash >/dev/null 2>&1; then
  trash "${APP_ZIP}" >/dev/null 2>&1 || true
  trash "${LAYER_ZIP}" >/dev/null 2>&1 || true
else
  rm -f "${APP_ZIP}" "${LAYER_ZIP}"
fi

cp -R "${ROOT_DIR}/app/service" "${APP_BUILD_DIR}/service"

"${PYTHON_BIN}" -m compileall "${ROOT_DIR}/app" >/dev/null

"${PYTHON_BIN}" -m pip install \
  --platform "${PLATFORM_TAG}" \
  --implementation cp \
  --python-version "${PYTHON_VERSION}" \
  --abi "${PYTHON_ABI}" \
  --only-binary=:all: \
  --target "${LAYER_BUILD_DIR}/python" \
  -r "${ROOT_DIR}/requirements.txt"

(
  cd "${APP_BUILD_DIR}"
  zip -qr "${APP_ZIP}" service
)

(
  cd "${LAYER_BUILD_DIR}"
  zip -qr "${LAYER_ZIP}" python
)

echo "Built ${APP_ZIP}"
echo "Built ${LAYER_ZIP}"
