# Kubernetes Cluster Deployment Guide

This document provides a comprehensive, step-by-step walkthrough to deploy your self-managed Kubernetes cluster on AWS. 

We are moving from a managed EKS environment to a **Kubeadm-provisioned cluster running directly on EC2 instances**. This approach reduces cost and gives you full control over the cluster lifecycle, networking, and storage components.

---

## Prerequisites

Before starting, ensure your Windows machine has:
1. **Terraform** installed.
2. **AWS CLI** configured with the correct IAM credentials.

*(Note: Terraform will automatically generate the SSH key for you during the apply step!)*

---

## Phase 1: Provision the Infrastructure (Terraform)

The first step is to create the raw AWS resources: the VPC, Subnets, EC2 Instances, Security Groups, and Application Load Balancer.

1. Open a PowerShell or Command Prompt terminal on your Windows machine.
2. Navigate to the Terraform directory:
   ```powershell
   cd e:\K8s\terraform
   ```
3. Initialize Terraform to download the necessary AWS provider plugins and modules:
   ```powershell
   terraform init
   ```
4. Apply the configuration. This will show you a plan of all the resources that will be created. Type `yes` to confirm:
   ```powershell
   terraform apply
   ```
5. **CRITICAL STEP:** Once Terraform finishes, it will print several outputs to the screen. You must **copy and save these outputs**, specifically:
   - `bastion_public_ip` (used to SSH into your environment)
   - `control_plane_private_ip`
   - `worker_1_private_ip`
   - `worker_2_private_ip`

---

## Phase 2: Update the Ansible Inventory

Ansible needs to know the exact IP addresses of the servers it is going to configure. Since Terraform just created these servers dynamically, we need to manually pass the IPs from Terraform to Ansible.

1. Open the file `e:\K8s\ansible\inventory.ini` in your IDE.
2. Replace the `X`, `Y`, and `Z` placeholders with the **Private IPs** from your Terraform outputs.

Your file should look exactly like this (with your real IPs):
```ini
[bastion]
localhost ansible_connection=local

[control_plane]
10.0.10.X ansible_host=10.0.10.X control_plane_ip=10.0.10.X

[workers]
10.0.10.Y ansible_host=10.0.10.Y
10.0.20.Z ansible_host=10.0.20.Z

[k8s_cluster:children]
control_plane
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/k8s-kubeadm.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

---

## Phase 3: Prepare the Bastion Host

The Bastion host is your secure jump-box. We will use it as our "Control Center" to run Ansible and manage the cluster, so it needs Ansible installed and the SSH key present.

1. **SSH into the Bastion** from your Windows machine:
   ```powershell
   ssh -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@<BASTION_PUBLIC_IP>
   ```
2. **Install Ansible** on the Bastion host:
   ```bash
   sudo apt update -y
   sudo apt install -y software-properties-common
   sudo add-apt-repository --yes --update ppa:ansible/ansible
   sudo apt install -y ansible
   ```
3. Type `exit` to disconnect from the Bastion host and return to your Windows terminal.

4. **Transfer your SSH Key and Ansible Code** from Windows to the Bastion host:
   ```powershell
   # Copy the SSH key securely
   scp -i e:\K8s\terraform\k8s-kubeadm.pem e:\K8s\terraform\k8s-kubeadm.pem ubuntu@<BASTION_PUBLIC_IP>:~/.ssh/k8s-kubeadm.pem

   # Copy the entire Ansible directory
   scp -i e:\K8s\terraform\k8s-kubeadm.pem -r e:\K8s\ansible ubuntu@<BASTION_PUBLIC_IP>:~/ansible
   ```

---

## Phase 4: Configure the Kubernetes Cluster (Ansible)

Now that the Bastion host has Ansible and your code, we will run the automation scripts to build the Kubernetes cluster.

1. **SSH back into the Bastion** host:
   ```powershell
   ssh -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@<BASTION_PUBLIC_IP>
   ```
2. **Secure the SSH key** so Ansible can use it without permission errors:
   ```bash
   chmod 400 ~/.ssh/k8s-kubeadm.pem
   ```
3. **Navigate to the Ansible directory** and verify connectivity to all 3 private nodes:
   ```bash
   cd ~/ansible
   ansible k8s_cluster -m ping
   ```
   *Expected Output: You should see a green "SUCCESS" block for all three IP addresses.*

4. **Execute the Playbooks in Order.** We are running them phased so if an error occurs, it is easy to pinpoint the exact failure.
   ```bash
   # 1. Prepare Nodes: Disables swap, configures networking, installs Containerd and Kubeadm
   ansible-playbook prep.yml

   # 2. Control Plane: Initializes the cluster, sets up admin access, and installs Calico Networking
   ansible-playbook control-plane.yml

   # 3. Workers: Joins both worker nodes to the cluster
   ansible-playbook workers.yml

   # 4. Storage: Installs the AWS EBS CSI driver and sets up your gp3 StorageClass
   ansible-playbook ebs-csi.yml

   # 5. Ingress: Installs Traefik as a DaemonSet to handle incoming web traffic
   ansible-playbook traefik.yml
   ```

---

## Phase 5: Verification & Next Steps

Once the playbooks complete, your Kubernetes cluster is fully operational. Because the Ansible scripts automatically configured your `~/.bashrc` on the Bastion host, you can run `kubectl` commands immediately!

Run this block of commands to verify the health of the entire system:

```bash
echo "=== Nodes ===" && kubectl get nodes -o wide
echo "=== System Pods ===" && kubectl get pods -n kube-system
echo "=== Calico ===" && kubectl get pods -n calico-system
echo "=== EBS CSI ===" && kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
echo "=== StorageClass ===" && kubectl get storageclass
echo "=== Traefik ===" && kubectl get pods -n traefik -o wide
```

### What to check for:
- **Nodes:** All 3 nodes should show a status of `Ready`.
- **System Pods:** CoreDNS, etcd, kube-apiserver should all be `Running`.
- **EBS CSI:** There should be 2-3 pods running successfully.
- **StorageClass:** You should see `ebs-sc` listed.
- **Traefik:** You should see 2 Traefik pods running (one on each worker node).

Once everything looks green and healthy, you are ready to deploy your Python application and attach the domain!
