# High-Performance Production Kubernetes Architecture

This repository contains the infrastructure and deployment configurations for our production-grade Kubernetes cluster on AWS EKS. We have recently upgraded from raw manifests to a highly scalable, zero-downtime, and maintainable setup using **Helm** and the **AWS Application Load Balancer (ALB)**.

## 🏗️ Architecture Overview

Our cluster handles multiple microservices, unified behind a highly-available AWS ALB.

- **Ingress Controller**: AWS Load Balancer Controller
- **Universal Helm Chart**: `microservice-chart/` manages deployments, services, ingress rules, HPA, and PVCs dynamically.
- **Routing**: ALB rules dynamically route traffic to specific services based on hostnames and paths.
- **Current Live Services**:
  - `flask-app`: The main Python application with persistent PVC storage.
  - `dummy-app`: A lightweight microservice.
  - `nginx-app`: A static HTML landing page application.

## 🚀 Key Improvements & Zero-Downtime

1. **Universal Helm Chart (`microservice-chart`)**: Replaced manual `yaml` files with a single customizable chart. This enforces consistency, drastically reduces boilerplate, and allows us to spin up new microservices in seconds.
2. **AWS Application Load Balancer (ALB)**: Replaced the default Traefik setup with a native AWS ALB. This provides native WAF integration, better metrics, automatic SSL/TLS termination, and highly robust cloud routing.
3. **Zero-Downtime Migration**: The transition from Traefik to ALB was executed transparently using a blue-green approach. Traefik was left intact while the ALB was provisioned, tested, and validated. DNS was then shifted seamlessly to the ALB, ensuring **zero dropped requests** and **no downtime** for live users.

## 📁 Repository Structure

```text
├── microservice-chart/        # The Universal Helm Chart for all our apps
│   ├── Chart.yaml
│   ├── values.yaml            # Default values (overridden per release)
│   └── templates/             # Universal templates (deployment, service, ingress, etc.)
├── 07-nginx-app.yaml          # Helm Values override for the NGINX App
├── 08-dummy-app.yaml          # Helm Values override for the Dummy App
├── app.py / Dockerfile        # Source code for the main Flask App
├── alb-sa.yaml                # ALB Controller ServiceAccount & IAM mappings
├── 05-ingress.yaml            # ALB Ingress routing rules
└── index.html                 # Source code for the NGINX Landing Page
```

## 🛠️ How to Deploy a Microservice

We use Helm to deploy and manage all services.

### 1. Deploying the Main Flask App
```bash
helm upgrade --install flask-app ./microservice-chart \
  --set image.repository=yourdockerhubuser/myapp \
  --set image.tag=1.0 \
  --set service.port=80
```

### 2. Deploying the Dummy App
Using a custom `values.yaml` file:
```bash
helm upgrade --install dummy-app ./microservice-chart -f 08-dummy-app.yaml
```

### 3. Deploying the Nginx App
```bash
helm upgrade --install nginx-app ./microservice-chart -f 07-nginx-app.yaml
```

## 🌐 Routing & Ingress

Traffic coming to `ahmeddev.tech` and `www.ahmeddev.tech` hits the AWS Application Load Balancer. The ALB reads the rules from `05-ingress.yaml` and routes traffic to the target NodePort services, which are dynamically managed by the AWS Load Balancer Controller.

To view the live ingress routes:
```bash
kubectl get ingress
```
