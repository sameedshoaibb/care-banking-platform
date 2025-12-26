# Ansible

Automated server setup that installs Docker, Kubernetes, Jenkins, and ArgoCD on your VM.

## What Gets Installed

- **Docker** - Container runtime for building and running applications
- **Kubernetes** - Container orchestration platform (single-node cluster)
- **Jenkins** - CI/CD automation server
- **Helm** - Kubernetes package manager
- **ArgoCD** - GitOps continuous deployment platform
- **UFW Firewall** - Security with configured inbound rules
- **System Security** - Non-root user with sudo, SSH key authentication, swap disabled

## Quick Start

**Step 1: Update Configuration**
Edit `inventory.ini` with your server IP:
```ini
[servers]
ubuntu-server ansible_host=YOUR_SERVER_IP ansible_user=ubuntu
```

**Step 2: Run Playbook**
```bash
ansible-playbook -i inventory.ini setup.yml
```

Takes about 10-15 minutes to complete.

## What Happens During Setup

1. **System** - Updates packages, installs essentials
2. **Docker** - Installs container runtime with security permissions
3. **Kubernetes** - Installs and initializes single-node cluster
4. **Jenkins** - Sets up CI/CD server on port 8080
5. **ArgoCD** - Configures GitOps platform
6. **Security** - Hardens VM with firewall and user permissions
7. **Verification** - Tests Docker and Kubernetes functionality

## After Setup Completes

- **Jenkins**: Access at `http://YOUR_SERVER_IP:8080`
- **ArgoCD**: Access at `http://YOUR_SERVER_IP:30080`
- **Kubernetes**: Ready for application deployments

## Setup Output Example

After running the playbook successfully, you'll see:

```
TASK [Display setup completion] ****
ok: [sameed] => {
    "msg": "✓ Setup Complete!
    
Services Running:
- Jenkins: http://YOUR_SERVER_IP:8080
- ArgoCD: http://YOUR_SERVER_IP:30080
- NGINX Test: http://YOUR_SERVER_IP:8888

Credentials:
- Jenkins Password: [generated-password]
- ArgoCD Password: [generated-password]

Security Tools:
- Trivy: trivy image <image-name>
- Syft: syft <image-name>

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

After the playbook completes successfully, verify the installation:

### Check System Services

SSH to your server and verify services:

```bash
ssh devops@YOUR_SERVER_IP

# Check Kubernetes
kubectl get nodes
kubectl get pods -A

# Check Docker
docker ps

# Check Jenkins status
systemctl status jenkins
```

### Test Network Connectivity

Verify that all services are accessible:

```bash
# Test Docker (NGINX container)
curl http://YOUR_SERVER_IP:8888

# Test Jenkins web interface
curl http://YOUR_SERVER_IP:8080
```

---

## User Management

The playbook creates two user accounts with different purposes:

**Primary User (ubuntu/sameed)**
- Used for interactive work and running Ansible
- Has sudo privileges and SSH access
- Used for manual server administration

**DevOps User (devops)**  
- Created specifically for CI/CD pipelines and automation
- Has Docker and Kubernetes access
- Used by Jenkins and automated scripts
- Includes kubeconfig for cluster access

Both users have sudo access and can run kubectl commands. This separation maintains security by isolating automated processes from interactive sessions.

---

## Network Configuration

The server configuration includes these network components:

**Server Networking**
- Server IP: Your VM private IP (assigned by cloud provider)
- Pod Network: 10.244.0.0/16 (Flannel CNI)
- Service Network: 10.96.0.0/12 (Kubernetes default)

**Firewall Rules**
- SSH (22): For remote access
- HTTP (80): For web applications  
- HTTPS (443): For secure web traffic
- Kubernetes API (6443): For cluster communication
- Jenkins (8080): For CI/CD web interface
- Kubelet (10250): For Kubernetes node communication
- Test NGINX (8888): For Docker verification

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

