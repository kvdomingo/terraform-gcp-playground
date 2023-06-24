provider "google" {
  project                     = var.project
  region                      = var.region
  zone                        = var.zone
  impersonate_service_account = var.tf_service_account
}

resource "google_compute_network" "vpc_network" {
  name                    = "tf-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "asia_east1_subnet1" {
  name          = "asia-east1-subnet1"
  ip_cidr_range = "10.224.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  stack_type    = "IPV4_ONLY"
}

resource "google_compute_firewall" "default_deny_incoming" {
  name      = "default-deny-incoming"
  network   = google_compute_network.vpc_network.id
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "default_allow_outgoing" {
  name      = "default-allow-outgoing"
  network   = google_compute_network.vpc_network.id
  direction = "EGRESS"
  priority  = 1000

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_cloud_run_v2_service" "dummy-nginx" {
  name     = "dummy-nginx"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    execution_environment            = "EXECUTION_ENVIRONMENT_GEN1"
    max_instance_request_concurrency = 300
    timeout                          = 60

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = "docker.io/bitnami/nginx"

      env {
        name  = "NGINX_HTTP_PORT_NUMBER"
        value = "8080"
      }

      ports {
        container_port = "8080"
      }

      resources {
        limits = {
          cpu    = 1
          memory = "512Mi"
        }
      }

      startup_probe {
        initial_delay_seconds = 20
        timeout_seconds       = 60
        period_seconds        = 20
        failure_threshold     = 3
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}
