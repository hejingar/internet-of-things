#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SERVER_IP="${SERVER_IP:-192.168.56.110}"
WORKER_IP="${WORKER_IP:-192.168.56.111}"
TOKEN_FILE="/vagrant/confs/node-token"
READY_FILE="/vagrant/confs/server-ready"

apt-get update -qq
apt-get install -y -qq curl ca-certificates

if [ ! -f /swapfile ]; then
  fallocate -l 512M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

api_is_up() {
  local code
  code="$(curl -sk -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://${SERVER_IP}:6443/readyz" || true)"
  [ "${code}" = "200" ] || [ "${code}" = "401" ]
}

echo "Waiting for K3s server..."
for _ in $(seq 1 120); do
  if [ -f "${READY_FILE}" ] && [ -s "${TOKEN_FILE}" ] && api_is_up; then
    break
  fi
  sleep 5
done

if [ ! -s "${TOKEN_FILE}" ] || ! api_is_up; then
  echo "K3s server is not ready on ${SERVER_IP}" >&2
  exit 1
fi

echo "Server is ready, waiting 30s before joining..."
sleep 30

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

echo "K3s agent started on ${WORKER_IP}, joining ${SERVER_IP}..."
echo "Verify on server: kubectl get nodes -o wide"
