# Manual Kubernetes Deployment Guide (AWS Free Tier)

If you did not have Ansible automation, you would have to SSH into every single node and type these commands manually. This guide outlines the exact manual steps required to reproduce this environment from scratch.

## Phase 1: Node Preparation (Run on ALL Nodes)
You must SSH into the Control Plane and both Worker Nodes and run all of these commands.

### 1. Create the 4GB Swap Hack
```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 2. Configure Linux Networking (Kernel Modules)
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

### 3. Install Container Runtime (Containerd)
```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y containerd.io

# Configure containerd to use Systemd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

### 4. Install Kubernetes Tools
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Force kubelet to allow Swap
echo 'Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

---

## Phase 2: Control Plane Initialization (Run on Control Plane ONLY)

### 1. Disable Leader Election (The Free Tier Hack)
```bash
cat <<EOF > /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/containerd/containerd.sock"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: "1.30.0"
networking:
  podSubnet: "10.244.0.0/16"
controllerManager:
  extraArgs:
    leader-elect: "false"
scheduler:
  extraArgs:
    leader-elect: "false"
EOF
```

### 2. Initialize the Cluster
```bash
sudo kubeadm init --config /tmp/kubeadm-config.yaml --ignore-preflight-errors=Swap,Mem,NumCPU
```
*(When this finishes, it will print out a `kubeadm join` command. Copy it!)*

### 3. Setup Admin Permissions
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 4. Install Flannel Networking
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

---

## Phase 3: Worker Node Join (Run on Worker Nodes ONLY)

Using the exact `kubeadm join` command that the Control Plane printed out in Phase 2, run it on both worker nodes. You MUST add the `--ignore-preflight-errors` flag to bypass the 1GB RAM limit.

```bash
sudo kubeadm join 10.0.10.170:6443 --token <your-secret-token> \
    --discovery-token-ca-cert-hash sha256:<your-hash> \
    --ignore-preflight-errors=Swap,Mem,NumCPU
```
