# Atlantis Helm Chart

![Auto Tag Release](https://github.com/k8sforge/atlantis-charts/actions/workflows/auto-tag.yml/badge.svg)

A production-ready Helm chart for deploying [Atlantis](https://www.runatlantis.io/) on Kubernetes. Atlantis automates Terraform workflows through pull requests.

---

## Overview

This is a **reusable Helm chart repository**.
The chart is versioned and published so it can be referenced by other repositories that deploy Atlantis.

---

## Chart Details

* **Chart Name**: `atlantis`
* **Chart Version**: `0.1.0`
* **App Version**: `latest` (Atlantis image tag)

---

## Distribution

This chart is published in two formats:

* **OCI (ghcr.io)** – modern, registry-based installs
* **Helm repository (GitHub Pages)** – classic `helm repo add` workflow

Both distributions publish the same chart versions.

---

## Quick Start

### Install via OCI (recommended)

```bash
helm install my-atlantis \
  oci://ghcr.io/k8sforge/atlantis-charts/atlantis \
  --version 0.1.0
```

If the registry is private:

```bash
helm registry login ghcr.io
```

---

### Install via Helm Repository (GitHub Pages)

```bash
helm repo add atlantis https://k8sforge.github.io/atlantis-charts
helm repo update

helm install my-atlantis atlantis/atlantis --version 0.1.0
```

---

### Install from Source (local development)

```bash
helm install my-atlantis .
```

---

## Prerequisites

* Kubernetes 1.20+
* `kubectl` configured
* Helm 3.x
* Argo Rollouts controller installed (for blue-green deployments)
* Ingress controller (nginx, traefik, or platform-specific such as AWS ALB)

---

## Configuration

The following table lists the main configurable parameters:

| Parameter                                                  | Description                  | Default                |
| ---------------------------------------------------------- | ---------------------------- | ---------------------- |
| `image.repository`                                         | Atlantis image repository    | `runatlantis/atlantis` |
| `image.tag`                                                | Atlantis image tag           | `latest`               |
| `replicaCount`                                             | Number of replicas           | `1`                    |
| `service.type`                                             | Service type                 | `ClusterIP`            |
| `service.port`                                             | Service port                 | `4141`                 |
| `deployment.strategy`                                      | Rollout strategy             | `blueGreen`            |
| `deployment.autoPromotionEnabled`                          | Auto-promote on deployment   | `false`                |
| `atlantis.repoAllowlist`                                   | Repository allowlist pattern | `github.com/*`         |
| `ingress.enabled`                                          | Enable ingress               | `true`                 |
| `ingress.className`                                        | Ingress class name           | `alb`                  |
| `resources.requests.memory`                                | Memory request               | `256Mi`                |
| `resources.requests.cpu`                                   | CPU request                  | `100m`                 |
| `resources.limits.memory`                                  | Memory limit                 | `512Mi`                |
| `resources.limits.cpu`                                     | CPU limit                    | `500m`                 |
| See [values.yaml](values.yaml) for the full configuration. |                              |                        |

---

## Authentication

Atlantis requires GitHub authentication.

### Option 1: GitHub Personal Access Token

```yaml
github:
  user: "your-username"
  token: "ghp_your_token"
  webhookSecret: "your-webhook-secret"
```

**Required scopes:**

* `repo`
* `admin:repo_hook`
* `write:repo_hook`

---

### Option 2: GitHub App (recommended for organizations)

```yaml
github:
  app:
    id: "123456"
    key: |
      -----BEGIN RSA PRIVATE KEY-----
      ...
      -----END RSA PRIVATE KEY-----
    installationId: "78901234"
  webhookSecret: "your-webhook-secret"
```

---

## Secrets Management

The chart expects a Kubernetes Secret named:

```
<release-name>-secrets
```

### Required keys

**Personal Access Token:**

* `github-user`
* `github-token`
* `webhook-secret`

**GitHub App:**

* `github-app-id`
* `github-app-key`
* `github-app-installation-id`
* `webhook-secret`

Example:

```bash
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='your-username' \
  --from-literal=github-token='ghp_your_token' \
  --from-literal=webhook-secret='your-secret' \
  --namespace=default
```

---

## Blue-Green Deployment

This chart uses **Argo Rollouts** with a blue-green strategy:

* **Active Service** receives production traffic
* **Preview Service** exposes the new version
* **Manual promotion** by default

### Promote a rollout

```bash
kubectl argo rollouts promote my-atlantis -n <namespace>
```

### Check rollout status

```bash
kubectl argo rollouts get rollout my-atlantis -n <namespace>
```

---

## Using This Chart from Another Repository (Repo B Pattern)

### Example dependency

```yaml
apiVersion: v2
name: my-deployment
type: application
version: 1.0.0

dependencies:
  - name: atlantis
    version: 0.1.0
    repository: https://k8sforge.github.io/atlantis-charts
```

Then:

```bash
helm dependency update
helm upgrade --install my-atlantis . -f values.yaml
```

> Note: Helm 3.8+ supports OCI-based dependencies, but classic repositories are shown here for maximum compatibility.

---

## Versioning and Releases

This chart follows semantic versioning.

To release a new version:

```bash
git tag v0.2.0
git push --tags
```

GitHub Actions will automatically publish the chart to:

* **GHCR (OCI)**
* **GitHub Pages (Helm repo)**

---

## Development

### Lint

```bash
helm lint .
```

### Dry-run

```bash
helm install my-atlantis . --dry-run --debug
```

### Render templates

```bash
helm template my-atlantis . -f values.yaml
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
