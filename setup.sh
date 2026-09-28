#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/bin"
ENV_NAME="alasight"
mkdir -p "${BIN_DIR}"

# Environment setup for alasight
if conda env list | grep -qE "^\s*${ENV_NAME}\s"; then
  echo "Updating existing conda env '${ENV_NAME}'"
  conda env update -n "${ENV_NAME}" -f "${REPO_DIR}/environment.yml" --prune
else
  echo "Creating conda env '${ENV_NAME}'"
  conda env create -f "${REPO_DIR}/environment.yml"
fi

# Setup alamem
#BUILD_ALAMEM=1 bash setup.sh to build alamem from source (needs rust)
if [ -x "${BIN_DIR}/alamem" ]; then
  echo "alamem already present at ${BIN_DIR}/alamem"
elif [ "${BUILD_ALAMEM:-0}" = "1" ]; then
  echo "Building alamem from source"
  tmp="$(mktemp -d)"
  git clone https://github.com/yunwilliamyu/alamem "${tmp}/alamem"
  ( cd "${tmp}/alamem" && RUSTFLAGS="-C target-cpu=native" cargo build --release )
  cp "${tmp}/alamem/target/release/alamem" "${BIN_DIR}/alamem"
  rm -rf "${tmp}"
else
  echo "Downloading prebuilt alamem"
  case "$(uname -m)" in
    x86_64)  url="https://github.com/yunwilliamyu/alamem/releases/latest/download/alamem-linux-x86_64-v3.tar.gz" ;;
    aarch64) url="https://github.com/yunwilliamyu/alamem/releases/latest/download/alamem-linux-aarch64.tar.gz" ;;
    *) echo "No prebuilt alamem for $(uname -m); re-run with BUILD_ALAMEM=1" >&2; exit 1 ;;
  esac
  curl -L "$url" | tar xz -C "${BIN_DIR}"
fi
chmod +x "${BIN_DIR}/alamem"

# Decompress shipped references
echo "Decompressing references."
unxz -k "${REPO_DIR}"/references-compressed/*.xz 2>/dev/null || true


echo ""
echo "Next steps - Run:"
echo "     export PATH=\"\$HOME/bin:\$PATH\""
echo "     conda activate alasight"