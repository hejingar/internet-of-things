#!/bin/bash
set -euo pipefail

# Prepare the PUBLIC GitHub repo Argo CD watches (run once, before correction).
#
# Prerequisite: create an empty public repo on GitHub with your login in the name, e.g.:
#   https://github.com/ael-youb/iot-ael-youb
#
# Usage:
#   GITHUB_REPO=https://github.com/ael-youb/iot-ael-youb ./prepare-github.sh

GITHUB_REPO="${GITHUB_REPO:-https://github.com/ael-youb/iot-ael-youb}"
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
  git -C "${CLONE_DIR}" pull --rebase origin main 2>/dev/null || git -C "${CLONE_DIR}" pull --rebase origin master 2>/dev/null || true
else
  echo "Cloning ${GITHUB_REPO} into ${CLONE_DIR}"
  git clone "${GITHUB_REPO}" "${CLONE_DIR}"
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
echo "GitHub repo ready: ${GITHUB_REPO}"
echo "Clone on correction VM: git clone ${GITHUB_REPO} ~/iot-ael-youb"
echo "Next: cd p3/scripts && sudo GITHUB_REPO=${GITHUB_REPO} ./install.sh"
