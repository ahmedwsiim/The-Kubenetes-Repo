# Kubernetes Configuration & Automation Guide

This document breaks down all the specific code changes and configurations you have made across your Terraform and Ansible codebases. It explains *why* these configurations exist and *how* they enable your `kubeadm` cluster to run flawlessly on the AWS Free Tier.

---

## 1. Infrastructure Provisioning (Terraform)
**File:** `terraform/modules/ec2/main.tf`

You used Infrastructure-as-Code (Terraform) to automate the deployment of your AWS servers. 
- **The Configuration:** You strictly used `instance_type = "t3.micro"` for your Bastion host, Control Plane, and Worker Nodes.
- **Why it matters:** This is the core requirement of your project. The `t3.micro` instances are the only ones available on the AWS Free Tier. By hardcoding this into Terraform, you guarantee that spinning up the cluster will not cost you any money. 

---

## 2. Server Preparation (Ansible: `node-prep` role)
**File:** `ansible/roles/node-prep/tasks/main.yml`

Before Kubernetes can be installed, the raw Ubuntu servers must be configured. You wrote an Ansible playbook to automate this deeply complex OS-level configuration.

### A. The 4GB Swap Hack
- **The Configuration:** You wrote tasks to execute `dd if=/dev/zero of=/swapfile bs=1M count=4096`, format it with `mkswap`, and enable it with `swapon`.
- **Why it matters:** Kubernetes (`kubeadm`) normally requires a strict minimum of 2GB of physical RAM. Your `t3.micro` instances only have 1GB. Without this configuration, the Linux Kernel would immediately trigger an "Out Of Memory" (OOM) panic and freeze the server. This 4GB "fake RAM" saves the cluster from crashing.

### B. Container Runtime Configuration
- **The Configuration:** You configured `containerd` to use `SystemdCgroup = true`.
- **Why it matters:** Kubernetes needs to aggressively manage the CPU and RAM of the containers it runs. By telling the container runtime (`containerd`) to integrate directly with Linux's native `systemd` process manager, Kubernetes can accurately limit and monitor container resource usage.

### C. Allowing Kubelet to use Swap
- **The Configuration:** You configured the `kubelet` agent to run with `failSwapOn: false`.
- **Why it matters:** By default, Kubernetes absolutely hates Swap memory and will intentionally crash if it detects it. You had to explicitly configure the Kubernetes node agent (`kubelet`) to accept that it is running on a Swap-enabled system.

---

## 3. Kubernetes Initialization (Ansible: `control-plane` role)
**File:** `ansible/roles/control-plane/tasks/main.yml`

This playbook executes the `kubeadm init` command that actually breathes life into the cluster and creates the Kubernetes API.

### A. Bypassing Timeouts (The Custom Config)
- **The Configuration:** Instead of running a plain `kubeadm init`, you dynamically created a `/tmp/kubeadm-config.yaml` file and passed it into the setup. This file explicitly set `leader-elect: "false"` for both the `kube-controller-manager` and `kube-scheduler`.
- **Why it matters:** Because your servers are relying on a slow AWS hard drive for "fake RAM" (the Swap file), the system experiences extreme "Disk IO Thrashing." When this happens, simple 5-second internal cluster health checks fail. Kubernetes assumes the node is dead and violently restarts the control plane in an endless loop. By disabling leader election, you forced Kubernetes to ignore those 5-second timeouts and stay alive.

### B. The Flannel Network Overlay
- **The Configuration:** You completely removed the `Calico` networking tasks and replaced them with a command to install `Flannel`: `kubectl apply -f kube-flannel.yml`. 
- **Why it matters:** Kubernetes doesn't come with networking out of the box; you have to install a plugin so Pods can talk to each other. Calico is the industry standard, but it uses over ~600MB of RAM just to run. On a 1GB server, this caused the deployment to completely lock up. Flannel is incredibly lightweight, taking less than 50MB of RAM, allowing your worker nodes to successfully join the cluster without freezing.

---

## 4. Global Variables (Ansible: `group_vars`)
**File:** `ansible/group_vars/all.yml`

- **The Configuration:** You updated the `pod_network_cidr` variable to `"10.244.0.0/16"`.
- **Why it matters:** This variable tells Kubernetes what IP addresses to assign to your Pods (e.g., the Nginx pod we tested). Flannel specifically looks for the `10.244.x.x` subnet by default. If you had left this as the old Calico subnet (`192.168.x.x`), the network plugin would have failed to start, and your pods would never get IP addresses!
