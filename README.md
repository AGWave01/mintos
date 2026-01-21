# Devops Engineer Home Assignment for

## Sonarqube on Minikube using Terraform and Helm


### Why Helm 3 and no Tiller?

- Tiller was **removed in Helm 3**
- Helm 3 is the current industry standard
- Requirement explicitly allows Helm 3

### Why custom postgresql Helm chart?

- Bitnami images and charts are no longer publicly accessible

---

## Quick start

```bash
git clone <repository_url>
cd mintos
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

After the script finishes, sonarqube will be running

---

## Bootstrap script

`scripts/bootstrap.sh` performs the following steps:

1. Installs base OS dependencies
2. Installs Docker and configures user permissions
3. Installs kubectl
4. Installs Minikube
5. Installs Helm 3
6. Installs Terraform
7. Starts Minikube with Docker driver
8. Enables Nginx Ingress Controller
9. Waits for ingress readiness
10. Configures kubeconfig environment variables
11. Runs Terraform to deploy:
    - Kubernetes namespace
    - Postgresql (custom Helm chart)
    - SonarQube

---

## Postgresql Details

- Installed via **custom Helm chart**
- Uses **official `postgres:16` image**
- Persistent volume enabled
- Credentials managed with secret
- Exposed internally

---

## Sonarqube Details

- Installed via official Sonarsource Helm chart
- Community Edition
- External postgresql configured
- Persistent storage enabled
- Startup and readiness probes configured
- Ingress enabled via nginx

---

## Accessing sonarqube

The script automatically computes an ingress host using `nip.io`:

```
http://sonarqube.<minikube_ip>.nip.io
```

### Make SSH tunnel to access service

```bash
ssh -L 9000:<minikube_ip>:80 user@<server_ip>
```

---

## Default SonarQube Credentials

| Username | Password |
| -------- | -------- |
| admin    | admin    |

---

## Validation Checklist

- `kubectl get pods -n sonarqube` shows all pods running
- Postgresql pod ready
- Sonarqube pod ready
- Ingress reachable via HTTP
- No manual steps required

---

## Notes

- Initial SonarQube startup may take several minutes
- Terraform timeout increased to handle slow startup
