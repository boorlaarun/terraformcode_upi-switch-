# ---------------------------------------------------------------------------
# Both APIs — ConfigMap (HTML content) + Deployment + Pod Anti-Affinity +Replicas + Service — kept together in this single file for easy review.
# Real web server used: NGINX, pulled from an EXISTING private ECR-since VPC-C has no internet access and public.ecr.aws is only reachable over the internet
# 
# ---------------------------------------------------------------------------
# Routing logic:
#   Call api-1-svc -> pod runs only on node_group_a_d (node1 + node4)
#                   -> nginx serves a page saying "Hi Arun Sai"
#
#   Call api-2-svc -> pod runs only on node_group_b_c (node2 + node3)
#                   -> nginx serves a page saying "Welcome Arun Sai"
#
# Anti-affinity is REQUIRED (hard rule), not preferred: the 2 replicas of
# each API are guaranteed to land on 2 different nodes/AZs, for realresilience.

# =========================== API - 1 ===========================

data "aws_ecr_repository" "nginx" {
  name = var.ecr_repository_name
}

# HTML content for API-1, injected into nginx via ConfigMap
resource "kubernetes_config_map" "api_1_html" {
  metadata {
    name      = "api-1-html"
    namespace = "default"
  }

  data = {
    "index.html" = <<-HTML
      <html>
        <head><title>API-1</title></head>
        <body>
          <h1>Hi Arun Sai</h1>
        </body>
      </html>
    HTML
  }
}

resource "kubernetes_deployment" "api_1" {
  depends_on = [module.eks]

  metadata {
    name      = "api-1"
    namespace = "default"
    labels    = { app = "api-1" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "api-1" }
    }

    template {
      metadata {
        labels = { app = "api-1" }
      }

      spec {
        # Only schedule on node_group_a_d (node1 + node4)
        node_selector = {
          "node-group" = "a-d"
        }

        # HARD rule: the 2 replicas MUST land on 2 different AZs
        # (node1 and node4 are in different AZs, so this guarantees split)
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              topology_key = "topology.kubernetes.io/zone"
              label_selector {
                match_labels = { app = "api-1" }
              }
            }
          }
        }

        container {
          name  = "api-1"
          image = "${data.aws_ecr_repository.nginx.repository_url}:${var.ecr_image_tag}"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "html-content"
            mount_path = "/usr/share/nginx/html"
          }

          resources {
            requests = { cpu = "50m", memory = "32Mi" }
            limits   = { cpu = "100m", memory = "64Mi" }
          }
        }

        volume {
          name = "html-content"
          config_map {
            name = kubernetes_config_map.api_1_html.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_1_svc" {
  depends_on = [module.eks]

  metadata {
    name      = "api-1-svc"
    namespace = "default"
  }

  spec {
    selector = { app = "api-1" }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# =========================== API - 2 ===========================

# HTML content for API-2, injected into nginx via ConfigMap
resource "kubernetes_config_map" "api_2_html" {
  metadata {
    name      = "api-2-html"
    namespace = "default"
  }

  data = {
    "index.html" = <<-HTML
      <html>
        <head><title>API-2</title></head>
        <body>
          <h1>Welcome Arun Sai</h1>
        </body>
      </html>
    HTML
  }
}

resource "kubernetes_deployment" "api_2" {
  depends_on = [module.eks]

  metadata {
    name      = "api-2"
    namespace = "default"
    labels    = { app = "api-2" }
  }

  spec {
    replicas = 2

    selector {
      match_labels = { app = "api-2" }
    }

    template {
      metadata {
        labels = { app = "api-2" }
      }

      spec {
        # Only schedule on node_group_b_c (node2 + node3)
        node_selector = {
          "node-group" = "b-c"
        }

        # HARD rule: the 2 replicas MUST land on 2 different AZs
        # (node2 and node3 are in different AZs, so this guarantees split)
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              topology_key = "topology.kubernetes.io/zone"
              label_selector {
                match_labels = { app = "api-2" }
              }
            }
          }
        }

        container {
          name  = "api-2"
          image = "${data.aws_ecr_repository.nginx.repository_url}:${var.ecr_image_tag}"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "html-content"
            mount_path = "/usr/share/nginx/html"
          }

          resources {
            requests = { cpu = "50m", memory = "32Mi" }
            limits   = { cpu = "100m", memory = "64Mi" }
          }
        }

        volume {
          name = "html-content"
          config_map {
            name = kubernetes_config_map.api_2_html.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_2_svc" {
  depends_on = [module.eks]

  metadata {
    name      = "api-2-svc"
    namespace = "default"
  }

  spec {
    selector = { app = "api-2" }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
