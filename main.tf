terraform {
  required_providers {
    docker     = { source = "kreuzwerker/docker", version = "~> 2.24.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29.0" }
    helm       = { source = "hashicorp/helm"}
  }
  required_version = ">= 1.3.0"
}

provider "docker" {}

provider "kubernetes" {
  config_path = "${path.module}/kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.module}/kubeconfig"
  }
}

# 1. Cria o Docker Volume para persistência
resource "docker_volume" "mongo_data" {
  name = "kind-mongo-data"
}

# 2. Cria o cluster KIND
resource "null_resource" "create_kind_cluster" {
  provisioner "local-exec" {
    command = "kind create cluster --name demo-cluster --config=kind-config.yaml --wait 60s"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name demo-cluster"
  }
  depends_on = [docker_volume.mongo_data]
}

# 3. Exporta o kubeconfig
resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.create_kind_cluster]
  provisioner "local-exec" {
    command = "kind get kubeconfig --name demo-cluster > kubeconfig"
  }
}

# 4. Aguarda API e cria o namespace demo
resource "null_resource" "create_namespace" {
  depends_on = [null_resource.get_kubeconfig]
  provisioner "local-exec" {
    command = <<-EOT
      for i in $(seq 1 30); do
        kubectl get ns kube-system >/dev/null 2>&1 && break
        sleep 2
      done
      kubectl apply -f manifests/namespace.yaml
    EOT
  }
}

# 5. Instala o CSI HostPath Driver
resource "null_resource" "install_csi_driver" {
  depends_on = [null_resource.create_namespace]
  provisioner "local-exec" {
    command = "kubectl apply -f manifests/csi-hostpath-driver.yaml"
  }
}


# 7. Instala CRDs de VolumeSnapshot (external-snapshotter)
resource "null_resource" "install_snapshot_crds" {
  depends_on = [
    null_resource.install_csi_driver,
  ]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.2.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
      kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.2.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
      kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v6.2.1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
    EOT
  }
}

# 8. Deploy da stack MongoDB + mongo-express + NetworkPolicy + VolumeSnapshot

resource "null_resource" "create_mongodb_secret" {
  depends_on = [
    null_resource.create_namespace
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f manifests/mongo-secret.yaml"
  }
}

resource "null_resource" "deploy_mongo_stack" {
  depends_on = [
    null_resource.create_namespace,
    null_resource.create_mongodb_secret,
    null_resource.install_csi_driver,
    null_resource.install_snapshot_crds
  ]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f manifests/mongo-replicaset.yaml
      kubectl apply -f manifests/mongo-network-policy.yaml
      kubectl apply -f manifests/volume-snapshot.yaml
	  kubectl apply -f manifests/mongodb-headless-service.yaml
    EOT
  }
}

resource "null_resource" "deploy_mongo_express" {
  depends_on = [
    null_resource.deploy_mongo_stack,
  ]
  provisioner "local-exec" {
    command = <<-EOT
      kubectl apply -f manifests/mongo-express-deployment.yaml
    EOT
  }
}
