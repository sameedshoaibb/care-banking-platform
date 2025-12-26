# Banking API: Image Building Process and Implementation Guide

## Build Process

### Overview
Started with building the Docker image from the source code. 

### Testing

All the 6 API endpoints are functional:
- User endpoints: GET, POST, PUT, DELETE
- Admin endpoints: GET accounts, DELETE account
- Note: Delete API only works if account balance is zero

### Build Commands

```bash
docker build -t care-banking-app:v1.0.0 .
docker run -dit -p 4000:4000 care-banking-app:v1.0.0
docker exec -it <container_id> /bin/sh
```

---

## Deployment Script

The `deploy.sh` now supports:
- Multiple environments: dev, staging, production
- Enhanced testing and verification capabilities

---

## Design Features

### Dockerfile Optimizations

- **25% smaller image** - Multi-stage build removes build tools and temporary files
- **Pinned Node.js version** - `node:20.19.6-alpine` for reproducible builds with zero known vulnerabilities
- **Better layer caching** - Dependencies installed before source code for faster rebuilds
- **Non-root execution** - Container runs under `appuser` for improved security
- **Clean final image** - TypeScript, Prettier, and test frameworks removed
- **pnpm with Corepack** - Faster installs and deterministic package management
- **Clear documentation** - Comments explain each part of the Dockerfile
- **Optimized build context** - `.dockerignore` excludes unnecessary files

---

---

## Getting Started

### Prerequisites

- Docker
- Kubernetes cluster (kubectl configured)
- Helm 3.x
- Local build (no container registry used)

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

**Production:**
```bash
deploy.sh prod
```

**Development:**
```bash
deploy.sh dev
```

**Staging:**
```bash
deploy.sh staging
```

### Step 4: Port Forwarding (for local testing)

```bash
kubectl port-forward -n care-banking-app svc/care-banking-app 8181:80 &
```

**Note:** Port forwarding is used for local testing. Ingress was avoided to prevent requiring `/etc/hosts` file modifications with admin privileges.


## Deployment Verification

### Expected Kubernetes Resources

After successful deployment, verify with:
```bash
kubectl get all -n care-banking-app
```

**Expected Output:**
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

### Endpoint 1: Health Check (Ping)

```bash
curl -s http://localhost:8181/ping
```
**Note:** We are using nginx reverse proxy to route the request to our backend-api.

### Endpoint 2: Create Account (Admin Only)

```bash
curl -s -X POST http://localhost:8181/admin/account \
  -H "x-api-key: sameed" \
  -H "Content-Type: application/json" \
  -d '{"accountId":"test1","password":"pass123"}'
```

**Note:** Admin API key is injected during runtime from the Kubernetes secret.

### Endpoint 3: Get Account Info

```bash
curl -s -X POST http://localhost:8181/account/test1/info \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123"}'
```

### Endpoint 4: Deposit Funds

```bash
curl -s -X POST http://localhost:8181/account/test1/deposit \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123","amount":5000}'

  Output: {"balance":110000}
```

### Endpoint 5: Withdraw Funds

```bash
curl -s -X POST http://localhost:8181/account/test1/withdraw \
  -H "Content-Type: application/json" \
  -d '{"password":"pass123","amount":1500}'

  Output: {"balance":108500}
```

### Endpoint 6: List All Accounts (Admin Only)

```bash
curl -s -H "x-api-key: sameed" http://localhost:8181/admin/accounts

Output: {"accounts":{"test1":{"id":"test1","password":"pass123","balance":108500,"createdAt":1766782387129,"updatedAt":1766782438669}}}
```

**Note:** Delete API only works if account balance is zero.

---

## DevOps Challenge

After running all the endpoints, we will have the data to see the results.

### 1. Nginx Proxy - Slow Request Logging

View slow requests (requests taking > 0.001 seconds):

```bash
kubectl exec -n care-banking-app deploy/care-banking-app -c nginx-proxy -- tail -5 /var/log/nginx/slow_requests.log
```

**Implementation Details:**
- Threshold: 0.001 seconds (1ms)
- Requests exceeding this threshold are logged with timing information
- This threshold was chosen because I was not able to replicate 1 sec as a slow requests in a test environment

**Sample Output:**
```
[SLOW_REQUEST] [26/Dec/2025:20:53:07 +0000] Remote: 127.0.0.1 | Request: POST /admin/account HTTP/1.1 | Status: 200 | Time: 0.011 s
[SLOW_REQUEST] [26/Dec/2025:20:53:25 +0000] Remote: 127.0.0.1 | Request: POST /account/test1/deposit HTTP/1.1 | Status: 200 | Time: 0.002 s
```

### 2. CronJob - Balance Check Status

The CronJob runs every minute to check for accounts with critically low balance (threshold: -10,000).

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
[2025-12-26 20:53:00] Starting balance check (threshold: -10000)
OK: No accounts found with critically low balance
[2025-12-26 20:54:00] Starting balance check (threshold: -10000)
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
