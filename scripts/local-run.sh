#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

export PYTHONPATH="${ROOT_DIR}/app${PYTHONPATH:+:${PYTHONPATH}}"
export FUNCTION_INDEX="${FUNCTION_INDEX:-0}"

"${PYTHON_BIN}" -m uvicorn service.main:app --host 0.0.0.0 --port "${PORT:-1188}"
