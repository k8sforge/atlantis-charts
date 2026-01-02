# atlantis Helm Chart

A production-ready Helm chart for deploying [Atlantis](https://www.runatlantis.io/) on Kubernetes. Atlantis automates Terraform workflows through pull requests.

## Overview

This is a **Helm chart repository** (Repo A pattern). This chart is reusable, versioned, and can be referenced by other repositories that need to deploy Atlantis.

## Chart Details

- **Chart Name**: `atlantis`
- **Current Version**: `0.1.0`
- **App Version**: `latest` (Atlantis image tag)

## Quick Start

### Installing the Chart

To install the chart with the release name `my-atlantis`:

```bash
helm install my-atlantis .
```

### Installing from a Helm Repository

If this chart is published to a Helm repository or OCI registry:

```bash
# Add the repository (example)
helm repo add atlantis-charts oci://ghcr.io/k8sforge/atlantis-charts
helm repo update

# Install
helm install my-atlantis atlantis-charts/atlantis --version 0.1.0
```

## Prerequisites

- Kubernetes 1.20+
- `kubectl` configured
- Argo Rollouts controller installed
- Ingress controller (nginx, traefik, or platform-specific like AWS ALB)
- Helm 3.x

## Configuration

The following table lists the configurable parameters and their default values:

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `image.repository` | Atlantis image repository | `runatlantis/atlantis` |
| `image.tag` | Atlantis image tag | `latest` |
| `replicaCount` | Number of replicas | `1` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `4141` |
| `deployment.strategy` | Rollout strategy | `blueGreen` |
| `deployment.autoPromotionEnabled` | Auto-promote on deployment | `false` |
| `atlantis.repoAllowlist` | Repository allowlist pattern | `github.com/*` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `alb` |
| `resources.requests.memory` | Memory request | `256Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.limits.cpu` | CPU limit | `500m` |

### Authentication

Atlantis requires GitHub authentication. Configure one of the following:

#### Option 1: GitHub Personal Access Token

```yaml
github:
  user: "your-username"
  token: "ghp_your_token"
  webhookSecret: "your-webhook-secret"
```

**Token Scopes Required:**

- `repo` - Full control of private repositories
- `admin:repo_hook` - Full control of repository hooks
- `write:repo_hook` - Write repository hooks

#### Option 2: GitHub App (Recommended for Organizations)

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

### Example Values

Create a `values.yaml` file:

```yaml
# values.yaml
replicaCount: 2

github:
  user: "my-username"
  token: "ghp_xxxxxxxxxxxx"
  webhookSecret: "my-secret"

ingress:
  enabled: true
  className: "alb"
  hosts:
    - host: atlantis.example.com
      paths:
        - path: /
          pathType: Prefix

atlantis:
  repoAllowlist: "github.com/myorg/*"
```

Then install:

```bash
helm install my-atlantis . -f values.yaml
```

## Secrets Management

The chart expects a secret named `{release-name}-secrets` to be created manually. The secret should contain:

**For Personal Access Token:**

- `github-user`
- `github-token`
- `webhook-secret`

**For GitHub App:**

- `github-app-id`
- `github-app-key`
- `github-app-installation-id`
- `webhook-secret`

Create the secret before installing:

```bash
kubectl create secret generic my-atlantis-secrets \
  --from-literal=github-user='your-username' \
  --from-literal=github-token='ghp_your_token' \
  --from-literal=webhook-secret='' \
  --namespace=default
```

## Blue-Green Deployment

This chart uses Argo Rollouts with Blue-Green strategy:

- **Active Service**: Production traffic
- **Preview Service**: New version for testing
- **Manual Promotion**: `autoPromotionEnabled: false` by default

### Promote New Version

```bash
kubectl argo rollouts promote my-atlantis -n <namespace>
```

### Check Rollout Status

```bash
kubectl argo rollouts get rollout my-atlantis -n <namespace>
```

## Using This Chart in Another Repository (Repo B Pattern)

This chart is designed to be referenced by other repositories. In your deployment repository:

### 1. Create a Chart.yaml with dependency

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

### 2. Update dependencies and install

```bash
helm dependency update
helm upgrade --install my-atlantis . -f values.yaml
```

## Versioning

This chart follows semantic versioning. To create a new version:

```bash
# Update Chart.yaml version
# Then tag and push
git tag v0.2.0
git push --tags
```

The GitHub Actions workflow will automatically package the chart when a tag is pushed.

## Development

### Lint the chart

```bash
helm lint .
```

### Dry-run installation

```bash
helm install my-atlantis . --dry-run --debug
```

### Template rendering

```bash
helm template my-atlantis . -f values.yaml
```

## Values Reference

See [values.yaml](values.yaml) for all available configuration options.

## License

MIT License - see [LICENSE](LICENSE) file for details.
