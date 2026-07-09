$ErrorActionPreference = "Stop"
$BastionIP = "13.62.117.1"
$KeyPath = "e:\K8s\terraform\k8s-kubeadm.pem"

Write-Host "Installing Ansible on Bastion..."
ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$BastionIP "sudo apt-get update -y && sudo apt-get install -y software-properties-common && sudo apt-add-repository --yes --update ppa:ansible/ansible && sudo apt-get install -y ansible"

Write-Host "Copying SSH Key..."
ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$BastionIP "mkdir -p ~/.ssh"
scp -o StrictHostKeyChecking=no -i $KeyPath $KeyPath "ubuntu@${BastionIP}:~/.ssh/k8s-kubeadm.pem"

Write-Host "Copying Ansible Directory..."
ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$BastionIP "rm -rf ~/ansible"
scp -o StrictHostKeyChecking=no -i $KeyPath -r e:\K8s\ansible "ubuntu@${BastionIP}:~/"

Write-Host "Running Ansible Playbooks..."
ssh -o StrictHostKeyChecking=no -i $KeyPath ubuntu@$BastionIP "chmod 400 ~/.ssh/k8s-kubeadm.pem && cd ~/ansible && ansible-playbook site.yml"
