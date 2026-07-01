# Dockerized Python App on Kubernetes — PVC, Service, Ingress, TLS

This folder contains everything for tasks 24–26:

```
app.py                  Flask app (writes/reads /data to prove PVC works)
Dockerfile               Builds the app image
requirements.txt         Python deps
build_and_push.sh        Builds & pushes the image to Docker Hub
01-app-deploy.yaml        PVC + Deployment + Service        (task 24)
02-ingress.yaml           HTTP ingress, no TLS yet           (task 25)
03-cluster-issuer.yaml    cert-manager Let's Encrypt issuer  (task 26)
04-ingress-tls.yaml       Same ingress, with TLS enabled     (task 26)
deploy.ps1                One-shot PowerShell script (Windows) doing it all
```

## Before you start — edit these placeholders

| File                    | Placeholder                  | Replace with                          |
|--------------------------|-------------------------------|----------------------------------------|
| 01-app-deploy.yaml       | `YOUR_DOCKERHUB_USERNAME`     | your Docker Hub username                |
| 02-ingress.yaml          | `app.yourdomain.com`          | your real domain/subdomain              |
| 04-ingress-tls.yaml      | `app.yourdomain.com` (x2)     | same domain                             |
| 03-cluster-issuer.yaml   | `you@example.com`             | your real email (for renewal notices)   |

## Step-by-step (manual)

### 1. Build & push the image (task 24)
```bash
# from inside this folder, on a machine with Docker installed
./build_and_push.sh yourdockerhubuser 1.0
```
This pushes `yourdockerhubuser/myapp:1.0`. Then edit the `image:` line in
`01-app-deploy.yaml` to match.

### 2. Deploy the app + PVC + Service (task 24)
```bash
kubectl apply -f 01-app-deploy.yaml
kubectl get pods,pvc,svc
```
Check the PVC is `Bound` (not `Pending`):
```bash
kubectl get pvc myapp-pvc
```
If it stays `Pending`, your cluster has no default StorageClass — run
`kubectl get storageclass` and uncomment/set `storageClassName` in
`01-app-deploy.yaml` accordingly.

Quick sanity test without ingress:
```bash
kubectl port-forward svc/myapp-svc 8080:80
curl http://localhost:8080
```

### 3. Install the ingress controller (task 25)
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx --create-namespace
```
Get the external IP:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```
- On a cloud provider (AKS/EKS/GKE/DigitalOcean/etc.) this gets a real
  external IP automatically after a minute or two.
- On bare-metal or a self-managed cluster it'll stay `<pending>` unless you
  install **MetalLB** to hand out LoadBalancer IPs — ask me and I'll add a
  MetalLB manifest tailored to your network range.
- On Minikube, run `minikube tunnel` in a separate terminal instead.

At your DNS provider, create an **A record**: `app.yourdomain.com` → that IP.

### 4. Apply the ingress (task 25)
```bash
kubectl apply -f 02-ingress.yaml
```
Wait for DNS to propagate (`nslookup app.yourdomain.com`), then:
```bash
curl http://app.yourdomain.com
```

### 5. Install cert-manager + issue TLS cert (task 26)
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl get pods -n cert-manager   # wait until all Running
kubectl apply -f 03-cluster-issuer.yaml
kubectl apply -f 04-ingress-tls.yaml
```
Watch the certificate get issued:
```bash
kubectl get certificate
kubectl describe certificate myapp-tls   # use if stuck for troubleshooting
```
Once `READY` is `True`:
```bash
curl https://app.yourdomain.com
```

## One-shot option (Windows / PowerShell)

After editing the placeholders above and building/pushing the image, just run:
```powershell
.\deploy.ps1
```
This installs ingress-nginx, deploys the app, installs cert-manager, and
applies the TLS ingress in one go.

## Notes
- The app writes a line to `/data/visits.log` on every request and reports
  the count — that's your proof the PVC is actually persisting data across
  pod restarts (`kubectl delete pod -l app=myapp` and reload the page to
  confirm the counter doesn't reset).
- `ReadWriteOnce` means the volume is only mountable read-write by a single
  node at a time — fine for `replicas: 1`. If you scale to multiple
  replicas later, you'll need `ReadWriteMany` storage (e.g. NFS, EFS) or a
  separate volume per pod (StatefulSet).
- Let's Encrypt certs auto-renew via cert-manager — nothing more to do
  after the first successful issuance.
