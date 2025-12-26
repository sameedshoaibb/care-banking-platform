#!/bin/bash
# Kubernetes Cluster Initialization Script

[[ $EUID -ne 0 ]] && echo "Run as root" && exit 1

PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Skip if already initialized
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "Cluster already initialized"
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl get nodes
    exit 0
fi

# Configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Load kernel modules
modprobe overlay
modprobe br_netfilter
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system > /dev/null

# Initialize Kubernetes cluster
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$PRIVATE_IP

# Setup kubectl access
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Setup kubectl for sudo user if exists
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    mkdir -p "$USER_HOME/.kube"
    cp /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
    chown -R "$SUDO_USER:$SUDO_USER" "$USER_HOME/.kube"
fi

# Setup kubectl for devops user
id "devops" &>/dev/null && {
    mkdir -p /home/devops/.kube
    cp /etc/kubernetes/admin.conf /home/devops/.kube/config
    chown -R devops:devops /home/devops/.kube
}

# Install Flannel CNI
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Allow scheduling on control plane (single-node)
kubectl taint nodes --all node-role.kubernetes.io/control-plane- 2>/dev/null || true

# Verify setup
echo "Waiting for cluster to be ready..."
sleep 30
echo "Cluster Status:"
kubectl get nodes
echo "Pod Status:"
kubectl get pods -A
