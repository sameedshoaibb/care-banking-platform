# Helm Chart Documentation

## Chart Structure

```
├── Chart.yaml                    # Chart metadata (name, version)
├── values.yaml                   # Default values for all environments
├── values.dev.yaml               # Development environment overrides
├── values.staging.yaml           # Staging environment overrides
├── values.prod.yaml              # Production environment overrides
```

---

## Kubernetes Components Overview

### Deployment

Deploys the main application with supporting containers:

**Containers:**
- **App Container**: Banking API service on port 4000
- **Nginx Sidecar**: Reverse proxy on port 80 with slow request logging (>0.001s)
- **Init Container**: Injects secrets from Kubernetes Secret into config file

**Key Features:**

- **Sidecar Pattern**: Nginx runs alongside the app for proxying and slow request logging
- **Init Container**: Generates `config.json` from template using Secret (ADMIN_API_KEY)
- **Security Hardening**: Non-root users, seccomp, dropped capabilities, read-only filesystem for nginx
- **Health Checks**: Liveness and readiness probes for app container
- **Resource Configuration**: Limits and requests fully configurable for all containers
- **Ephemeral Storage**: In-memory volumes for logs, cache, and runtime directories (fast and stateless)
- **Config Management**: Stored in ConfigMaps and injected cleanly into containers
- **Pod Priority**: PriorityClass ensures app stays running during node resource pressure
- **Access Control**: ServiceAccount with RBAC for controlled permissions

### Service
Provides internal DNS and load balancing:
- Exposes application inside the Kubernetes cluster
- Service discovery for inter-pod communication

### ConfigMaps

Stores non-sensitive configuration:

**App Config (`config.json`)**
- Template file mounted into container
- Contains placeholder for admin API key
- Injected with secret value at runtime

**Nginx Config (`nginx.conf`)**
- Reverse proxy settings
- Slow request logging configuration
- Request timeout and buffer settings 

### Secrets
Stores sensitive data:
- **API Keys**: Admin API key stored securely
- **Reason**: Credentials should never be in images or config files

### CronJob
Scheduled balance checking task:
- **Schedule**: Every minute (configurable)
- **Action**: Calls `/admin/accounts` endpoint
- **Function**: Finds accounts below balance threshold (-10,000)
- **Output**: Logs alerts to email

### Resource Management

**ResourceQuota**
- Prevents resource starvation in the namespace
- Limits total CPU and memory usage

**PriorityClass**
- Determines pod eviction priority
- Keeps critical pods running during resource constraints

**PodDisruptionBudget**
- Maintains service availability during maintenance
- Ensures minimum replicas are always running

### Network & Security

**NetworkPolicy**
- Implements least privilege access
- Allows traffic TO pods only from other banking-api pods and DNS (port 53)

**RBAC (Role-Based Access Control)**
- Pods only have permissions for actions they need
- Follows principle of least privilege

### Auto-scaling

**HPA (Horizontal Pod Autoscaler)**
- Status: Disabled
- Reason: Application state is not persistent, so scaling cannot be done reliably without data consistency issues

**VPA (Vertical Pod Autoscaler)**
- Status: Disabled
- Reason: Requires installation of additional Custom Resource Definitions (CRDs) in the cluster

### Ingress
External routing configuration:
- **Status**: Currently disabled
- **Reason**: Uses port-forward for local testing to avoid requiring sudo access for `/etc/hosts` modification

## Future Improvements

### Persistent Storage
Implement **PersistentVolumes (PV) and PersistentVolumeClaims (PVC)** to enable horizontal scaling with data consistency:
- Store account balances and transaction history persistently
- Enables Horizontal Pod Autoscaler (HPA) for reliable scaling
- Current limitation: Application state is in-memory, preventing safe scaling

### External Secret Management
Integrate with a cloud-native secrets provider for enhanced security:
- Use AWS Secrets Manager, HashiCorp Vault, or cloud provider equivalents
- Eliminate secrets from ConfigMaps and manual injection
- Implement secret rotation and audit logging
- Reference secrets via environment variables or mount paths

---

## Common Helm Commands

### Deploy Application

**Production:**
```bash
helm upgrade --install banking-api ./helm -f ./helm/values.prod.yaml
```

**Staging:**
```bash
helm upgrade --install banking-api ./helm -f ./helm/values.staging.yaml
```

**Development:**
```bash
helm upgrade --install banking-api ./helm -f ./helm/values.dev.yaml
```

### Preview Changes

```bash
helm diff upgrade --install banking-api ./helm -f ./helm/values.staging.yaml
```

### Validate Chart

```bash
helm lint ./helm -f ./helm/values.dev.yaml
```

### Generate Manifests

```bash
helm template banking-api ./helm -f ./helm/values.prod.yaml
```

### Remove Release

```bash
helm uninstall banking-api
```

---

