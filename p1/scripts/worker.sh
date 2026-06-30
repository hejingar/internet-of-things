#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SERVER_IP="${SERVER_IP:-192.168.56.110}"
WORKER_IP="${WORKER_IP:-192.168.56.111}"
TOKEN_FILE="/vagrant/confs/node-token"

apt-get update -qq
apt-get install -y -qq curl ca-certificates

if [ ! -f /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

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
ready=0
for _ in $(seq 1 120); do
  if api_is_up; then
    ready=$((ready + 1))
    [ "${ready}" -ge 3 ] && break
  else
    ready=0
  fi
  sleep 5
done

if [ "${ready}" -lt 3 ]; then
  echo "K3s API is not reachable on ${SERVER_IP}" >&2
  exit 1
fi

K3S_TOKEN="$(tr -d '\n' < "${TOKEN_FILE}")"

if ! command -v k3s >/dev/null 2>&1; then
  export INSTALL_K3S_SKIP_START=true
  curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="${K3S_TOKEN}" \
    INSTALL_K3S_EXEC="--node-external-ip=${WORKER_IP} --flannel-iface=eth1" \
    sh -
fi

systemctl enable k3s-agent
systemctl reset-failed k3s-agent 2>/dev/null || true
systemctl start k3s-agent &

echo "Waiting for k3s-agent to join ${SERVER_IP}..."
for _ in $(seq 1 120); do
  if systemctl is-active --quiet k3s-agent 2>/dev/null; then
    echo "K3s agent joined ${SERVER_IP}"
    exit 0
  fi
  if ! api_is_up; then
    echo "K3s API on ${SERVER_IP} is not responding, retrying..." >&2
  fi
  sleep 5
done

echo "k3s-agent failed to join the cluster" >&2
journalctl -u k3s-agent -n 30 --no-pager >&2 || true
exit 1
