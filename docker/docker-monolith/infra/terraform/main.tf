provider "google" {
  version = "~>2.15"
  project = var.project
  region  = var.region
}
module "docker" {
  source           = "./modules/docker"
  name             = var.name
  machine_type     = var.machine_type
  zone             = var.zone
  app_tags         = var.app_tags
  public_key_path  = var.public_key_path
  app_disk_image   = var.app_disk_image
  node_count       = var.node_count
}
module "vpc" {
  source        = "./modules/vpc"
  source_ranges = ["0.0.0.0/0"]
}

