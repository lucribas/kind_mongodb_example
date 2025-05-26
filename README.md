
# Requisitos

- docker
- kubectl
- helm
- kind

## 1. Instalar o kubectl (CLI do Kubernetes)

```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl

# Adiciona chave GPG do Google Cloud
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Adiciona repositório do Kubernetes
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Instala o kubectl
sudo apt update
sudo apt install -y kubectl
```

## 2. Instalar o helm (gerenciador de pacotes para Kubernetes)

```bash
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg

echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
  sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

sudo apt update
sudo apt install -y helm
```

## 3. Instalação do Kind


```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep tag_name | cut -d '"' -f 4)/kind-linux-amd64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```


# Run


Create cluster
```bash
./cluster_create.bash
```

open http://localhost:30000/
admin/admin



get Info about cluster
```bash
./cluster_info.source
```


Destroy cluster
```bash
./cluster_destroy.bash
```






