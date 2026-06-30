#!/bin/bash
set -euo pipefail

GITHUB_REPO="${GITHUB_REPO:-https://github.com/ael-youb/iot-ael-youb}"
CLUSTER_NAME="${CLUSTER_NAME:-iot}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P3_DIR="$(dirname "${SCRIPT_DIR}")"

export DEBIAN_FRONTEND=noninteractive

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "[1/6] Installing Docker..."
if ! command -v docker >/dev/null 2>&1; then
  run_root apt-get update -qq
  run_root apt-get install -y -qq docker.io curl ca-certificates
  run_root systemctl enable --now docker
fi

echo "[2/6] Installing k3d..."
if ! command -v k3d >/dev/null 2>&1; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "[3/6] Installing kubectl..."
if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /tmp/kubectl
  run_root install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
fi

echo "[4/6] Creating k3d cluster..."
k3d cluster delete "${CLUSTER_NAME}" 2>/dev/null || true
k3d cluster create "${CLUSTER_NAME}" \
  -p "8888:8888@loadbalancer" \
  --wait

echo "[5/6] Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=600s

kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "[6/6] Configuring Argo CD application..."
sed "s|__GITHUB_REPO__|${GITHUB_REPO}|g" "${P3_DIR}/confs/application.yaml" | kubectl apply -f -

echo "Waiting for application sync..."
for _ in $(seq 1 60); do
  if kubectl get pods -n dev 2>/dev/null | grep -q Running; then
    break
  fi
  sleep 5
done

kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
kubectl get applications -n argocd

echo
echo "Test: curl http://localhost:8888/"
curl -s http://localhost:8888/ || echo "(app not ready yet — check GitHub repo is public and pushed)"
echo
echo "Argo CD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "GitHub repo expected: ${GITHUB_REPO}"
