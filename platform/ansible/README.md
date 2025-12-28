# Ansible

Automated server setup that installs Docker, Kubernetes, Jenkins, and ArgoCD on your VM.

## What Gets Installed

- **Docker** - Container runtime
- **Kubernetes** - Container orchestration (single node)
- **kubelet & kubectl** - Kubernetes node and CLI tools
- **kubeadm** - Kubernetes cluster initialization tool
- **Flannel CNI** - Pod networking (10.244.0.0/16)
- **Jenkins** - CI/CD server (port 8080)
- **Helm** - Kubernetes package manager
- **ArgoCD** - GitOps deployment (port 30080)
- **ArgoCD CLI** - Command-line tool for GitOps management
- **Trivy** - Vulnerability scanner for images and code
- **Syft** - Software Bill of Materials (SBOM) generator
- **UFW Firewall** - Security hardening
- **System Security** - Non-root user, SSH keys, swap disabled

## Quick Start

**Step 1: Update Configuration**
Edit `inventory.ini` with your server IP:
```ini
ubuntu-server ansible_host=YOUR_SERVER_IP ansible_user=ubuntu
```

**Step 2: Run Playbook**
```bash
ansible-playbook -i inventory.ini setup.yml
```

Takes about 10-15 minutes to complete.

## What Happens During Setup

1. **System** - Updates packages, installs essentials
2. **Docker** - Installs container runtime
3. **Kubernetes** - Initializes single-node cluster
4. **Jenkins** - Sets up CI/CD server
5. **ArgoCD** - Configures GitOps platform
6. **Security** - Hardens VM with firewall and users
7. **Verification** - Tests Docker and Kubernetes

## After Setup

Services will be running at:
- **Jenkins**: http://YOUR_SERVER_IP:8080
- **ArgoCD**: http://YOUR_SERVER_IP:30080
- **NGINX Test Container**: http://YOUR_SERVER_IP:8888 (Docker verification)
- **Kubernetes**: Ready for deployments

## Setup Output Example

After running the playbook successfully, you'll see Output like this:

```
TASK [Display setup completion] ****
ok: [sameed] => {
    "msg": "✓ Setup Complete!
    
Ready for application deployment!"
}

PLAY RECAP ****
sameed: ok=50 changed=37 unreachable=0 failed=0 skipped=1
```

### What This Means

- **ok=50** - 50 tasks completed successfully
- **changed=37** - 37 changes made to the system
- **failed=0** - No failures
- **Total time** - ~10-15 minutes

All services are now running and ready to use!

## Verification

After the playbook completes, verify installation:

```bash
ssh devops@YOUR_SERVER_IP

# Check cluster
kubectl get nodes
kubectl get pods -A

# Check services
systemctl status jenkins
curl http://YOUR_SERVER_IP:8080
```

---

## User Management

The playbook creates two users:

**ubuntu/sameed** - For manual server administration with sudo and SSH access

**devops** - For CI/CD pipelines with Docker, Kubernetes, and kubeconfig access

---

## Network Configuration

**Pod Network** - 10.244.0.0/16 (Flannel CNI)

**Service Network** - 10.96.0.0/12 (Kubernetes default)

**Open Ports** - SSH (22), HTTP (80), HTTPS (443), NGINX Test (8888), Jenkins (8080), Kubernetes API (6443), Kubelet (10250), ArgoCD (30080, 30443)

---

## Troubleshooting

### Connection Issues

**Cannot connect to server:**

```bash
# Copy SSH key to server first
ssh-copy-id ubuntu@YOUR_SERVER_IP

# Test SSH connection manually
ssh -i ~/.ssh/your_key ubuntu@YOUR_SERVER_IP

# Then test Ansible connectivity
ansible all -m ping
```

### Playbook Execution Issues

**Playbook fails during execution:**

```bash
# Run with verbose output for debugging
ansible-playbook setup.yml -vvv
```

### Service Issues

**Jenkins not accessible:**

```bash
# Check Jenkins status
systemctl status jenkins

# Check firewall rules
sudo ufw status

# Check Jenkins logs
sudo journalctl -u jenkins
```

**Kubernetes cluster issues:**

```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes -o wide

# Check kubelet logs
sudo journalctl -xeu kubelet 

# Check pod events
kubectl describe pod <pod-name> -n kube-system
```

