# High-Performance Kubernetes Architecture: ALB + Traefik Two-Tier Ingress

This repository contains the deployment configurations for our production-grade Kubernetes cluster on AWS EKS. We have implemented a highly scalable, zero-downtime **Two-Tier Ingress Architecture** using the **AWS Application Load Balancer (ALB)** and **Traefik**.

## 🏗️ Architecture Overview

Our cluster handles multiple microservices, beautifully unified behind a two-tier routing system:

1. **Tier 1: AWS Application Load Balancer (ALB)** 
   - Acts as the public-facing entry point to the internet.
   - Handles **native SSL/TLS termination** via AWS Certificate Manager (ACM).
   - Secures our traffic and routes all requests for `thechamp.app` into the cluster.
2. **Tier 2: Traefik (Internal API Gateway)**
   - Runs as an internal `ClusterIP` service.
   - Receives all decrypted traffic from the ALB.
   - Uses powerful `IngressRoute` CRDs and `Middleware` to dynamically route requests based on URL paths, strip prefixes, and distribute traffic to our microservices.

### 🚀 Current Live Services
- `myapp`: Our original core deployment.
- `nginx-deployment`: Served at `thechamp.app/nginx`.
- `dummy-deployment`: Served at `thechamp.app/dummy`.
- `billing-deployment`: A dedicated billing microservice.

## 📁 Repository Structure

```text
├── 05-ingress.yaml            # ALB Ingress rules (routes Internet -> Traefik)
├── 07-nginx-app.yaml          # Nginx Deployment + Service + Traefik IngressRoute
├── 08-dummy-app.yaml          # Dummy Deployment + Service + Traefik IngressRoute
├── patch-traefik.yaml         # Patch to convert Traefik to ClusterIP
├── alb-sa.yaml                # ALB Controller ServiceAccount & IAM mappings
└── Dockerfile / app.py        # Source code for the core apps
```

## 🛠️ How It Works (The Traffic Flow)

When a user visits `https://thechamp.app/nginx`:
1. **ALB** receives the HTTPS request, decrypts it using the ACM certificate (`f79bdd39-c116-43ec-b754-d94acc8a3ea6`), and forwards it to the `traefik` service on port 80.
2. **Traefik** sees the request for `/nginx`. It looks at the `IngressRoute` in `07-nginx-app.yaml`.
3. Traefik triggers the `strip-nginx-prefix` Middleware to remove `/nginx` from the URL, so the Nginx pod just sees a request for `/`.
4. The traffic is handed to the `nginx-svc`, which sends it to the running `nginx-deployment` pod.

## 🔄 Zero-Downtime Migration Log

We achieved this setup without dropping a single request! 
1. Traefik was originally a public `LoadBalancer`.
2. We deployed the native AWS ALB (`05-ingress.yaml`) and configured it to point to Traefik.
3. We updated our DNS for `thechamp.app` to point to the new ALB.
4. Once traffic smoothly transitioned to the ALB, we ran a zero-downtime `helm upgrade` and `kubectl patch` to downgrade the old Traefik load balancer to a purely internal `ClusterIP` (`patch-traefik.yaml`). 

## 📝 Deploying a New Microservice

To add a new microservice (like `dummy-app`), you simply need to create a single YAML file containing:
1. Your `Deployment` (the pods)
2. Your `Service` (internal port mapping)
3. Your Traefik `Middleware` (if you need to strip the URL prefix)
4. Your Traefik `IngressRoute` (routing a specific path to your service)

Apply it via:
```bash
kubectl apply -f your-new-app.yaml
```
Traffic will instantly be routed by Traefik with full SSL protection automatically provided by the ALB upstream!
