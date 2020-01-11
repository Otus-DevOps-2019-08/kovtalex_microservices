provider "google" {
  version = "~>2.15"
  project = var.project
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  addons_config {
    kubernetes_dashboard {
      disabled = var.disable_dashboard
    }
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = var.pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    disk_size_gb = 20

    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    tags = ["kubernetes"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_firewall" "default" {
  name = "kubernetes"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kubernetes"]
}