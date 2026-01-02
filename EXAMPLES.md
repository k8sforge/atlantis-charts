# Usage Examples

This document provides practical examples of how to use the Atlantis Helm chart.

## Table of Contents

1. [Basic Installation](#basic-installation)
2. [Installation with Custom Values](#installation-with-custom-values)
3. [Installation from OCI Registry](#installation-from-oci-registry)
4. [AWS ALB Example](#aws-alb-example)
5. [NGINX Ingress Example](#nginx-ingress-example)
6. [GitHub App Authentication](#github-app-authentication)
7. [Using as a Dependency](#using-as-a-dependency)

---

## Basic Installation

### Install from Local Chart

```bash
# Clone the repository
git clone https://github.com/k8sforge/atlantis-charts.git
cd atlantis-charts

# Install with default values
helm install my-atlantis .
```

### Install with Override Values

```bash
# Install and override specific values
helm install my-atlantis . \
  --set replicaCount=2 \
  --set ingress.enabled=true \
  --set ingress.className=alb \
  --set ingress.hosts[0].host=atlantis.mycompany.com
```

---

## Installation with Custom Values

### Create a Custom Values File

Create `my-atlantis-values.yaml`:

```yaml
# my-atlantis-values.yaml
replicaCount: 2

image:
  repository: runatlantis/atlantis
  tag: v0.28.0  # Use specific version instead of latest

# GitHub Authentication
github:
  user: "my-github-username"
  token: "ghp_xxxxxxxxxxxx"  # Will be stored in secret
  webhookSecret: "my-webhook-secret"

# Atlantis Configuration
atlantis:
  repoAllowlist: "github.com/myorg/*"
  repoConfig:
    repos:
      - id: "/.*/"
        allowed_overrides:
          - "workflow"
        apply_requirements:
          - "approved"
    workflows:
      default:
        plan:
          steps:
            - "init"
            - "plan"
        apply:
          steps:
            - "init"
            - "apply"

# Ingress Configuration
ingress:
  enabled: true
  className: "alb"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
  hosts:
    - host: atlantis.mycompany.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: atlantis-tls
      hosts:
        - atlantis.mycompany.com

# Resources
resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

### Install with Custom Values

```bash
# Create the secret first (required)
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='my-github-username' \
  --from-literal=github-token='ghp_xxxxxxxxxxxx' \
  --from-literal=webhook-secret='my-webhook-secret' \
  --namespace=default

# Install with custom values
helm install my-atlantis . -f my-atlantis-values.yaml
```

---

## Installation from OCI Registry

If the chart is published to an OCI registry (like GitHub Container Registry):

```bash
# For OCI registries, use direct reference (no helm repo add needed)
helm install my-atlantis oci://ghcr.io/k8sforge/atlantis-charts/atlantis --version 0.1.0

# Or with custom values
helm install my-atlantis oci://ghcr.io/k8sforge/atlantis-charts/atlantis \
  --version 0.1.0 \
  -f my-atlantis-values.yaml

# Alternative: If published to a traditional Helm repository
# helm repo add k8sforge https://k8sforge.github.io/atlantis-charts
# helm repo update
# helm install my-atlantis k8sforge/atlantis --version 0.1.0
```

---

## AWS ALB Example

Complete example for AWS EKS with ALB Ingress Controller:

```yaml
# aws-alb-values.yaml
replicaCount: 2

github:
  user: "atlantis-bot"
  token: "ghp_xxxxxxxxxxxx"
  webhookSecret: "super-secret-webhook-key"

atlantis:
  repoAllowlist: "github.com/myorg/*"

ingress:
  enabled: true
  className: "alb"
  annotations:
    # Internet-facing ALB
    alb.ingress.kubernetes.io/scheme: internet-facing
    # Use IP mode for Fargate or when using security groups
    alb.ingress.kubernetes.io/target-type: ip
    # Listen on HTTP and HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    # Backend protocol
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    # Health check
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    # SSL redirect
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    # Certificate ARN (if using ACM)
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:us-east-1:123456789:certificate/abc123"
  hosts:
    - host: atlantis.mycompany.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: atlantis-tls
      hosts:
        - atlantis.mycompany.com

resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

Install:

```bash
# Create secret
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='atlantis-bot' \
  --from-literal=github-token='ghp_xxxxxxxxxxxx' \
  --from-literal=webhook-secret='super-secret-webhook-key' \
  --namespace=default

# Install
helm install my-atlantis . -f aws-alb-values.yaml
```

---

## NGINX Ingress Example

Example for NGINX Ingress Controller with cert-manager:

```yaml
# nginx-values.yaml
replicaCount: 2

github:
  user: "atlantis-bot"
  token: "ghp_xxxxxxxxxxxx"
  webhookSecret: "super-secret-webhook-key"

atlantis:
  repoAllowlist: "github.com/myorg/*"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    # Use cert-manager for TLS
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    # Force HTTPS redirect
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # Rate limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
  hosts:
    - host: atlantis.mycompany.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: atlantis-tls
      hosts:
        - atlantis.mycompany.com

resources:
  requests:
    memory: "512Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

Install:

```bash
# Create secret
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='atlantis-bot' \
  --from-literal=github-token='ghp_xxxxxxxxxxxx' \
  --from-literal=webhook-secret='super-secret-webhook-key' \
  --namespace=production

# Install
helm install my-atlantis . -f nginx-values.yaml --namespace production
```

---

## GitHub App Authentication

Using GitHub App instead of Personal Access Token:

```yaml
# github-app-values.yaml
github:
  # GitHub App configuration
  app:
    id: "123456"
    key: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEA...
      -----END RSA PRIVATE KEY-----
    installationId: "78901234"
  webhookSecret: "my-webhook-secret"

atlantis:
  repoAllowlist: "github.com/myorg/*"
```

Create secret with GitHub App credentials:

```bash
# Create secret with GitHub App
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-app-id='123456' \
  --from-file=github-app-key=./github-app-key.pem \
  --from-literal=github-app-installation-id='78901234' \
  --from-literal=webhook-secret='my-webhook-secret' \
  --namespace=default

# Install
helm install my-atlantis . -f github-app-values.yaml
```

---

## Using as a Dependency

If you have a deployment repository that uses this chart as a dependency:

### 1. Create Chart.yaml in your deployment repo

```yaml
# Chart.yaml
apiVersion: v2
name: my-service-deploy
description: Deployment configuration for my service
type: application
version: 1.0.0

dependencies:
  - name: atlantis
    version: 0.1.0
    repository: oci://ghcr.io/k8sforge/atlantis-charts
```

### 2. Create values.yaml

```yaml
# values.yaml
atlantis:
  replicaCount: 2

  github:
    user: "atlantis-bot"
    token: "ghp_xxxxxxxxxxxx"
    webhookSecret: "my-secret"

  ingress:
    enabled: true
    className: "alb"
    hosts:
      - host: atlantis.mycompany.com
        paths:
          - path: /
            pathType: Prefix
```

### 3. Install

```bash
# Create secret first
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='atlantis-bot' \
  --from-literal=github-token='ghp_xxxxxxxxxxxx' \
  --from-literal=webhook-secret='my-secret'

# Update dependencies
helm dependency update

# Install
helm install my-atlantis . -f values.yaml
```

---

## Upgrade and Rollback

### Upgrade

```bash
# Upgrade with new values
helm upgrade my-atlantis . -f my-atlantis-values.yaml

# Upgrade with new chart version from OCI registry
helm upgrade my-atlantis oci://ghcr.io/k8sforge/atlantis-charts/atlantis --version 0.2.0
```

### Rollback

```bash
# Check release history
helm history my-atlantis

# Rollback to previous version
helm rollback my-atlantis

# Rollback to specific revision
helm rollback my-atlantis 3
```

---

## Blue-Green Deployment (Argo Rollouts)

When using Argo Rollouts with blue-green strategy:

```bash
# Deploy new version
helm upgrade my-atlantis . -f values.yaml

# Check rollout status
kubectl argo rollouts get rollout my-atlantis

# Promote new version (switch traffic)
kubectl argo rollouts promote my-atlantis

# Abort rollout if needed
kubectl argo rollouts abort my-atlantis
```

---

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=atlantis
kubectl logs -l app.kubernetes.io/name=atlantis
```

### Check Service

```bash
kubectl get svc -l app.kubernetes.io/name=atlantis
```

### Check Ingress

```bash
kubectl get ingress -l app.kubernetes.io/name=atlantis
kubectl describe ingress my-atlantis-ingress
```

### Validate Chart

```bash
# Lint
helm lint .

# Dry-run
helm install my-atlantis . --dry-run --debug

# Template rendering
helm template my-atlantis . -f values.yaml
```

---

## Next Steps

1. **Configure GitHub webhook** to point to your Atlantis URL (e.g., `https://atlantis.mycompany.com/events`)
2. **Set webhook secret** in GitHub to match the value in your Kubernetes secret
3. **Test with a sample Terraform PR** in an allowed repository
4. **Monitor logs and metrics** using `kubectl logs` and monitoring tools
5. **Set up alerts** for failed deployments and rollout issues
