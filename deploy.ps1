# deploy.ps1
# Run from inside the k8s-python-app folder in PowerShell.
# This installs ingress-nginx and cert-manager, then applies all manifests.
#
# Prerequisites:
#   - kubectl configured against your cluster
#   - helm installed (https://helm.sh/docs/intro/install/)
#   - You already built & pushed the image and edited the `image:` line
#     in 01-app-deploy.yaml
#   - You already edited the domain in 02-ingress.yaml / 04-ingress-tls.yaml
#     and the email in 03-cluster-issuer.yaml

Write-Host ">> Installing ingress-nginx via Helm"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx --create-namespace

Write-Host ">> Waiting for ingress-nginx controller pod to be ready..."
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=180s

Write-Host ">> Ingress external IP (point your DNS A record here):"
kubectl get svc -n ingress-nginx ingress-nginx-controller

Write-Host ">> Deploying app (PVC + Deployment + Service)"
kubectl apply -f 01-app-deploy.yaml

Write-Host ">> Applying ingress (HTTP only, for now)"
kubectl apply -f 02-ingress.yaml

Write-Host ">> Installing cert-manager"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

Write-Host ">> Waiting for cert-manager pods to be ready..."
kubectl wait --namespace cert-manager `
  --for=condition=ready pod `
  --all --timeout=180s

Write-Host ">> Applying ClusterIssuer"
kubectl apply -f 03-cluster-issuer.yaml

Write-Host ">> Applying TLS-enabled ingress"
kubectl apply -f 04-ingress-tls.yaml

Write-Host ""
Write-Host "Done. Check certificate status with:"
Write-Host "  kubectl get certificate"
Write-Host "  kubectl describe certificate myapp-tls"
Write-Host ""
Write-Host "Once DNS has propagated and the cert is Ready, visit:"
Write-Host "  https://app.yourdomain.com"
