resource "google_compute_instance" "docker" {
  count        = var.node_count
  name         = "${var.name}${count.index+1}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.app_tags
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
  boot_disk {
    initialize_params {
      image = var.app_disk_image
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-docker"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["docker-machine"]
}
