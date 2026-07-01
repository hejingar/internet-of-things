#!/bin/bash
set -euo pipefail

SERVER_IP="${1:-192.168.56.110}"
export DEBIAN_FRONTEND=noninteractive
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

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
    --disable metrics-server" sh -
fi

echo "Waiting for K3s..."
for _ in $(seq 1 120); do
  if k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; then
    break
  fi
  sleep 5
done

if ! k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; then
  echo "K3s is not ready" >&2
  exit 1
fi

mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sed -i "s/127.0.0.1/${SERVER_IP}/" /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

for app in app1 app2 app3; do
  kubectl create configmap "${app}-html" \
    --from-file=index.html="/vagrant/confs/${app}/index.html" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f "/vagrant/confs/${app}/deployment.yaml"
  kubectl apply -f "/vagrant/confs/${app}/service.yaml"
done

kubectl apply -f /vagrant/confs/ingress.yaml

for app in app1 app2 app3; do
  kubectl wait --for=condition=available "deployment/${app}" --timeout=300s
done

sleep 15
echo "P2 ready on ${SERVER_IP}"
echo "Test from VM: curl -H 'Host: app1.com' http://127.0.0.1"
