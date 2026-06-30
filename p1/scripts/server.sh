#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
SERVER_IP="${SERVER_IP:-192.168.56.110}"
TOKEN_FILE="/vagrant/confs/node-token"
READY_FILE="/vagrant/confs/server-ready"

apt-get update -qq
apt-get install -y -qq curl ca-certificates

if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 \
    --tls-san=${SERVER_IP} \
    --node-external-ip=${SERVER_IP} \
    --bind-address=${SERVER_IP} \
    --flannel-iface=eth1 \
    --disable traefik \
    --disable servicelb" sh -
fi

echo "Waiting for K3s API to be ready..."
for _ in $(seq 1 120); do
  if k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    break
  fi
  sleep 5
done

if ! k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; then
  echo "K3s API is not ready on the server" >&2
  exit 1
fi

mkdir -p "$(dirname "${TOKEN_FILE}")"
cp /var/lib/rancher/k3s/server/node-token "${TOKEN_FILE}"
chmod 644 "${TOKEN_FILE}"
echo "ready" > "${READY_FILE}"

if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
fi

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sed -i "s/127.0.0.1/${SERVER_IP}/" /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

echo "K3s server is ready on ${SERVER_IP}"
