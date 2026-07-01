#!/bin/bash
set -euo pipefail

# Optional helper — manual first push via SSH is fine too (see manifests/README).
#
# Prerequisite: empty PUBLIC repo on GitHub, SSH key configured (git@github.com).
#
# Usage:
#   ./prepare-github.sh
#   GITHUB_SSH=git@github.com:hejingar/ael-youb-iot.git ./prepare-github.sh

GITHUB_SSH="${GITHUB_SSH:-git@github.com:hejingar/ael-youb-iot.git}"
GITHUB_HTTPS="${GITHUB_HTTPS:-https://github.com/hejingar/ael-youb-iot}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P3_DIR="$(dirname "${SCRIPT_DIR}")"
MANIFESTS_DIR="${P3_DIR}/manifests"
CLONE_DIR="${CLONE_DIR:-${HOME}/iot-ael-youb}"

if [ ! -d "${MANIFESTS_DIR}" ]; then
  echo "Missing manifests directory: ${MANIFESTS_DIR}" >&2
  exit 1
fi

if [ -d "${CLONE_DIR}/.git" ]; then
  echo "Updating existing clone: ${CLONE_DIR}"
  git -C "${CLONE_DIR}" pull --rebase origin main 2>/dev/null || \
    git -C "${CLONE_DIR}" pull --rebase origin master 2>/dev/null || true
else
  echo "Cloning ${GITHUB_SSH} into ${CLONE_DIR}"
  git clone "${GITHUB_SSH}" "${CLONE_DIR}"
fi

cp "${MANIFESTS_DIR}/namespace.yaml" \
   "${MANIFESTS_DIR}/deployment.yaml" \
   "${MANIFESTS_DIR}/service.yaml" \
   "${CLONE_DIR}/"

cd "${CLONE_DIR}"
git add namespace.yaml deployment.yaml service.yaml

if git diff --cached --quiet; then
  echo "Nothing to commit — repo already up to date."
else
  git commit -m "deploy wil42/playground:v1"
  git push origin HEAD
fi

echo
echo "GitHub repo ready (SSH): ${GITHUB_SSH}"
echo "Argo CD uses HTTPS:      ${GITHUB_HTTPS}"
echo "Clone on correction VM:  git clone ${GITHUB_SSH} ~/iot-ael-youb"
echo "Install: sudo GITHUB_REPO=${GITHUB_HTTPS} ./install.sh"
