# Care Banking App

A Node.js/TypeScript REST API that provides 6 basic banking operations. Nginx is used as a reverse proxy with slow request logging enabled that sends request to the api. A Kubernetes CronJob runs every minute to check for accounts with critically low balance. 


## What's Inside

- **Source code** - Node.js/TypeScript banking app with account management, deposits, withdrawals, and admin operations
- **Dockerfile** - Multi-stage build optimized for security and size (non-root user, pinned dependencies, 25% smaller)
- **Helm charts** - Kubernetes deployment manifests with environment-specific values (dev, staging, prod)
- **Jenkinsfile** - 13-stage CI/CD pipeline with security scans, Docker builds, and automated deployments
- **Nginx proxy** - Reverse proxy with slow request logging for performance monitoring
- **CronJob** - Automated balance checks running every minute

## API Overview

Six endpoints handle all banking operations:
- **User endpoints** - GET account info, POST deposit/withdraw
- **Admin endpoints** - POST create account, GET/DELETE all accounts
- **Health check** - GET ping for service verification

## Docker Optimizations

Our Docker image is optimized for performance and security:
- **smaller image** - Multi-stage build removes build tools and temporary files
- **Pinned Node.js version** - node:20.19.6-alpine for reproducible builds
- **Better layer caching** - Dependencies installed before source code
- **Non-root execution** - Container runs under appuser for security
- **pnpm with Corepack** - Faster installs and deterministic package management

## Deployment Strategy

The `deploy.sh` script automates Helm deployments across multiple environments (dev, staging, prod). Instead of manual Helm commands, it handles everything: diff changes, linting the chart, rendering templates, and executing deployments,keeping configuration consistent across all environments.

## Getting Started

### Prerequisites
- Docker and Kubernetes cluster running
- Helm 3.x installed
- kubectl configured
- care-banking-app secret created (see Step 2)

### Step 1: Build Docker Image
```bash
cd care-banking-app
docker build -t care-banking-app:v1.0.0 .
```

### Step 2: Create Kubernetes Secret
```bash
kubectl create secret generic care-banking-app-key \
  --from-literal=adminApiKey=sameed \
  -n care-banking-app
```

**Note:** Secrets are created outside of Helm for security reasons. They are injected into the app at runtime via an init container. For more details, see `helm/README.md`

### Step 3: Deploy Application
Deploy to your desired environment:
```bash
deploy.sh prod     # Production
deploy.sh staging  # Staging
deploy.sh dev      # Development
```

### Step 4: Verify Deployment
```bash
kubectl get all -n care-banking-app
kubectl port-forward -n care-banking-app svc/care-banking-app 8181:80 &
```

Access the app at `http://localhost:8181`


## Verification

After deployment, verify resources are running:

```bash
kubectl get all -n care-banking-app
```

**Actual Output:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
pod/care-banking-app-b645867fb-d4t8z   2/2     Running   0          17m
pod/care-banking-app-b645867fb-mm4p5   2/2     Running   0          113s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
service/care-banking-app   ClusterIP   10.101.28.192   <none>        80/TCP,4000/TCP   62m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/care-banking-app   2/2     2            2           62m

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/care-banking-app-b645867fb   2         2         2       17m

NAME                                                   REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/care-banking-app   Deployment/care-banking-app   <unknown>/70%   2         5         2          62m

NAME                                           SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob.batch/care-banking-app-balance-check   */1 * * * *   False     0        54s             2m43s

NAME                                                COMPLETIONS   DURATION   AGE
job.batch/care-banking-app-balance-check-29446370   1/1           3s         114s
job.batch/care-banking-app-balance-check-29446371   1/1           4s         54s
```

---

## API Testing

Test the endpoints using curl (make sure port-forward is running):

### Health Check
```bash
curl -s http://localhost:8181/ping
```

All requests route through the Nginx reverse proxy, which sits in front of the API.

### Create Account (Admin)
```bash
curl -s -X POST http://localhost:8181/admin/account \
  -H "x-api-key: sameed" \
  -H "Content-Type: application/json" \
  -d '{"accountId":"test1","password":"pass123"}'
```

### Get Account Info
```bash
curl -s -X POST http://localhost:8181/account/test1/info \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123"}'
```

### Deposit Funds
```bash
curl -s -X POST http://localhost:8181/account/test1/deposit \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123","amount":5000}'
```

### Withdraw Funds
```bash
curl -s -X POST http://localhost:8181/account/test1/withdraw \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123","amount":1500}'
```
**Output:** {"balance":108500}

### List All Accounts (Admin)
```bash
curl -s -H "x-api-key: sameed" http://localhost:8181/admin/accounts
```
**Output:** {"accounts":{"test1":{"id":"test1","password":"pass123","balance":108500,"createdAt":1766782387129,"updatedAt":1766782438669}}}

---

## Monitoring & Automation

### 1. Nginx Proxy - Slow Request Logging

View slow requests (requests taking > 0.001 seconds):

```bash
kubectl exec -n care-banking-app deploy/care-banking-app -c nginx-proxy -- tail -5 /var/log/nginx/slow_requests.log
```

Example output shows request timing data:
```
[SLOW_REQUEST] [26/Dec/2025:20:53:07 +0000] Remote: 127.0.0.1 | Request: POST /admin/account HTTP/1.1 | Status: 200 | Time: 0.011 s
[SLOW_REQUEST] [26/Dec/2025:20:53:25 +0000] Remote: 127.0.0.1 | Request: POST /account/test1/deposit HTTP/1.1 | Status: 200 | Time: 0.002 s
```

### 2. CronJob - Balance Check Status

Runs every minute to detect accounts with critically low balance (threshold: -10,000):

**View CronJob logs:**
```bash
kubectl logs -n care-banking-app -l job-type=cronjob --tail=10
```

**Sample Output:**
```
[2025-12-26 20:55:00] Starting balance check (threshold: -10000)
OK: No accounts found with critically low balance
[2025-12-26 20:52:00] Starting balance check (threshold: -10000)
OK: No accounts found with critically low balance
```

---

## Additional Deployment Commands

**Preview changes before deploying:**
```bash
deploy.sh prod diff
```

**Validate Helm chart:**
```bash
deploy.sh prod lint
```

**Generate manifest without deploying:**
```bash
deploy.sh prod template
```

**Uninstall deployment:**
```bash
deploy.sh prod uninstall
```
