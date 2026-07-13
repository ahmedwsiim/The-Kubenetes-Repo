# Kubernetes on AWS Free Tier: Architecture & Usage Guide

## 1. Overall Architecture
This cluster is deployed entirely on **AWS Free Tier** using `t3.micro` instances. It follows a highly secure, private network topology:

- **Bastion Host (Public):** The only server exposed to the public internet. It acts as a secure "jump box" to reach the internal Kubernetes nodes.
- **Control Plane Node (Private):** The master node that manages the cluster state, API, and workloads.
- **Worker Nodes (Private):** Two worker nodes where your actual application containers (Pods) run.

Because the Control Plane and Worker nodes are in a private subnet, they cannot be accessed directly from the internet. All traffic must flow through the Bastion host.

---

## 2. How to Log In to the Machines
You must use the Bastion host as a "Jump" server (`-J`) to reach your private cluster nodes. 

From your local machine, use the following commands with your SSH key (`k8s-kubeadm.pem`):

**Log into the Bastion Host:**
```bash
ssh -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@13.62.117.1
```

**Log into the Control Plane Node (via Bastion):**
```bash
ssh -J ubuntu@13.62.117.1 -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@10.0.10.170
```

**Log into Worker Node 1 (via Bastion):**
```bash
ssh -J ubuntu@13.62.117.1 -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@10.0.10.129
```

**Log into Worker Node 2 (via Bastion):**
```bash
ssh -J ubuntu@13.62.117.1 -i e:\K8s\terraform\k8s-kubeadm.pem ubuntu@10.0.20.70
```

### Managing the Cluster with `kubectl`
The Bastion host has been pre-configured with the cluster's administrative credentials. 
To manage the cluster (e.g., `kubectl get pods`), simply log into the Bastion host. You do not need to SSH into the Control Plane to manage the cluster.

---

## 3. The Hardware Constraint (`t3.micro` Limitations)
The biggest challenge of this deployment is the hardware limitation of the AWS Free Tier. 
- A `t3.micro` instance has only **1GB of RAM**.
- The `kubeadm` Kubernetes installer strictly requires a minimum of **2GB of RAM**.

Running a 2GB platform on a 1GB server causes the Linux kernel to run completely out of memory (OOM), which results in the entire server freezing and crashing. To bypass this impossible hardware limit, we had to implement a series of extreme infrastructure hacks.

### Hack 1: 4GB Swap Space
Because the server lacked physical RAM, we created a massive 4GB "Swap File" on the AWS hard drive (EBS volume). This forced the Linux kernel to use the slow hard drive as "fake memory." While this successfully prevented the server from crashing, it introduced extreme "disk thrashing"—making the server run incredibly slow because hard drives are significantly slower than physical RAM. We had to pass the `--ignore-preflight-errors=Swap,Mem,NumCPU` flag to force `kubeadm` to accept this configuration.

### Hack 2: Disabling Leader Election
Because the hard drive was working at 100% capacity (thrashing), internal cluster health checks were taking longer than the default **5-second timeout**. This caused the Kubernetes `kube-controller-manager` and `kube-scheduler` to panic and crash in an endless loop because they thought the database was offline. We injected a custom `kubeadm-config.yaml` to completely disable leader election and bypass these strict 5-second timeouts.

### Hack 3: Switching to Flannel
Modern Kubernetes networking plugins like **Calico** are extremely feature-rich but are massive memory hogs. Trying to decompress and run the heavy Calico containers on the 1GB instances caused the setup script to freeze indefinitely. 

To solve this, we ripped out Calico and installed **Flannel**. Flannel is an older, incredibly lightweight networking plugin. Because its memory footprint is a fraction of the size of Calico, the 1GB servers were able to successfully decompress and run it without completely locking up the operating system. Flannel acts as the internal nervous system of the cluster, assigning IP addresses to your pods (like the `10.244.x.x` subnet) and allowing them to communicate with each other across different worker nodes.
