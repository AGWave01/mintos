#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "\n==> $*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1
}

sudo_if_needed() {
  if [[ "${EUID}" -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

install_ubuntu_deps() {
  log "Installing base dependencies (Ubuntu)"
  sudo_if_needed apt-get update -y
  sudo_if_needed apt-get install -y ca-certificates gnupg lsb-release unzip jq git
}

install_docker_ubuntu() {
  if require_cmd docker; then
    log "Docker already installed"
    return
  fi

  log "Installing Docker (Ubuntu)"
  sudo_if_needed install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo_if_needed gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo_if_needed chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo_if_needed tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo_if_needed apt-get update -y
  sudo_if_needed apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  if ! groups "$USER" | grep -q docker; then
    sudo_if_needed usermod -aG docker "$USER"
  fi

  if command -v newgrp >/dev/null 2>&1; then
    log "Applying docker group in current shell (newgrp docker)"
    newgrp docker <<'EOF'
echo "docker group applied"
EOF
  fi
}

install_kubectl() {
  if require_cmd kubectl; then
    log "kubectl already installed"
    return
  fi
  log "Installing kubectl"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo_if_needed install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
}

install_minikube() {
  if require_cmd minikube; then
    log "minikube already installed"
    return
  fi
  curl -fsSLo /tmp/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  sudo_if_needed install -m 0755 /tmp/minikube /usr/local/bin/minikube
}

install_helm() {
  if require_cmd helm; then
    log "helm already installed"
    return
  fi
  log "Installing helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_terraform() {
  if require_cmd terraform; then
    log "terraform already installed"
    return
  fi
  log "Installing terraform"
  TF_VERSION="1.7.5"
  curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
  (cd /tmp && unzip -o terraform.zip)
  sudo_if_needed install -m 0755 /tmp/terraform /usr/local/bin/terraform
}

start_minikube() {
  log "Starting minikube"
  minikube start --driver=docker --cpus=2 --memory=3072

  log "Enabling ingress addon"
  minikube addons enable ingress

  log "Waiting for ingress controller to be ready"
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s
}

ensure_kubeconfig() {

  export KUBECONFIG="${HOME}/.kube/config"
  export HELM_KUBECONFIG="${HOME}/.kube/config"

  if [[ ! -f "${KUBECONFIG}" ]]; then
    echo "ERROR: kubeconfig not here ${KUBECONFIG}"
    exit 1
  fi

  kubectl config current-context >/dev/null

  log "Using kubeconfig ${KUBECONFIG}"
}

apply_terraform() {
  local repo_root
  repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

  local ip host
  ip="$(minikube ip)"
  host="sonarqube.${ip}.nip.io"
  export TF_VAR_ingress_host="$host"

  pushd "${repo_root}/terraform" >/dev/null
  terraform init -upgrade
  terraform apply -auto-approve
  popd >/dev/null

  log "Done. SonarQube should become available at:"
  echo "  http://${host}"
  echo
  log "Watch pods:"
}

main() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "This bootstrap.sh is designed for Ubuntu Linux minimal."
    echo "For macOS: use the macOS instructions in README (brew), or run this repo inside an Ubuntu VM."
    exit 1
  fi

  install_ubuntu_deps
  install_docker_ubuntu
  install_kubectl
  install_minikube
  install_helm
  install_terraform
  start_minikube
  ensure_kubeconfig
  apply_terraform
}

main "$@"