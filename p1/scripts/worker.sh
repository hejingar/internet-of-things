#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SERVER_IP="${SERVER_IP:-192.168.56.110}"
TOKEN_FILE="/vagrant/confs/node-token"

apt-get update -qq
apt-get install -y -qq curl ca-certificates

api_is_up() {
  local code
  code="$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 3 "https://${SERVER_IP}:6443/readyz" || true)"
  [ "${code}" = "200" ] || [ "${code}" = "401" ]
}

echo "Waiting for K3s server token..."
for _ in $(seq 1 120); do
  if [ -s "${TOKEN_FILE}" ]; then
    break
  fi
  sleep 5
done

if [ ! -s "${TOKEN_FILE}" ]; then
  echo "K3s server token not found in ${TOKEN_FILE}" >&2
  exit 1
fi

echo "Waiting for K3s API on ${SERVER_IP}..."
for _ in $(seq 1 120); do
  if api_is_up; then
    break
  fi
  sleep 5
done

if ! api_is_up; then
  echo "K3s API is not reachable on ${SERVER_IP}" >&2
  exit 1
fi

K3S_TOKEN="$(tr -d '\n' < "${TOKEN_FILE}")"

if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${K3S_TOKEN}" \
    sh -
fi

echo "K3s agent joined ${SERVER_IP}"
