terraform {
  required_providers {
    kind = {
      source = "tehcyx/kind"
      version = "0.0.16"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.8.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }

  required_version = ">= 1.0.0"
}

variable "kind_cluster_config_path" {
  type        = string
  description = "The location where this cluster's kubeconfig will be saved to."
  default     = "~/.kube/config"
}

provider "kind" {
}

provider "kubernetes" {
  config_path = pathexpand(var.kind_cluster_config_path)
}

provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kind_cluster_config_path)
  }
}

resource "kind_cluster" "k8s_cluster" {
  name = "k8s-cluster"
  kubeconfig_path = pathexpand(var.kind_cluster_config_path)
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<EOT
        kind: InitConfiguration
        nodeRegistration:  
            kubeletExtraArgs:    
              node-labels: "ingress-ready=true"
        EOT
      ]
       extra_port_mappings {
        container_port = 80
        host_port      = 80 
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
    }
  }
}

resource "helm_release" "ingress_controller" {
  name       = "ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.0.1"

  namespace        = "ingress-controller"
  create_namespace = true

  values = [file("nginx-ingress-values.yaml")]

  depends_on = [kind_cluster.k8s_cluster]
}

resource "null_resource" "wait_for_ingress" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for the ingress controller...\n"
      kubectl wait --namespace ${helm_release.ingress_controller.namespace} \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    EOF
  }

  depends_on = [helm_release.ingress_controller]
}

resource "helm_release" "trino_cluster" {
  name       = "trino-cluster"

  repository = "https://trinodb.github.io/charts"
  chart      = "trino"

  values = [file("trino-values.yaml")]

  depends_on = [null_resource.wait_for_ingress]

}

resource "helm_release" "minio_cluster" {
  name       = "minio-cluster"

  repository = "https://charts.min.io"
  chart      = "minio"

  values = [file("minio-values.yaml")]

  depends_on = [null_resource.wait_for_ingress]

  # https://artifacthub.io/packages/helm/minio-official/minio#create-buckets-after-install
  set {
    name  = "buckets[0].name"
    value = "lakehouse"
  }

  set {
    name  = "buckets[0].policy"
    value = "public"
  }

  set {
    name  = "buckets[0].purge"
    value = "true"
  }

}

resource "helm_release" "postgresql" {
  name       = "postgresql"

  repository = "https://cetic.github.io/helm-charts"
  chart      = "postgresql"

  values = [file("postgresql-values.yaml")]

  depends_on = [null_resource.wait_for_ingress]
}

resource "kubernetes_ingress_v1" "trino_ingress" {
  metadata {
    name = "trino-ingress"
    namespace = "ingress-controller"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$1"
    }
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/trino(?:/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = "trino-cluster"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/(ui(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "trino-cluster"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/(v1(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "trino-cluster"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/minio(?:/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(api(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(login(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(styles(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(static(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(images(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(ws(?:/|$).*)"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-cluster-console"
              port {
                number = 9001
              }
            }
          }
        }
        path {
          path = "/(postgresql?:/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = "postgresql"
              port {
                number = 5432
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.trino_cluster, helm_release.minio_cluster, helm_release.postgresql]
}
