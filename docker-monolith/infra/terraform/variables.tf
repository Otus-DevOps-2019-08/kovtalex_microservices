variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  default     = "europe-west1"
}
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}
variable app_disk_image {
  description = "Disk image for docker instance"
  default     = "ubuntu-1604-lts"
}
variable name {
  description = "Name for docker instance"
  default     = "docker-host"
}
variable machine_type {
  description = "Machine type for docker instance"
  default     = "n1-standard-1"
}
variable node_count {
  description = "count of instances"
  default     = 1
}
variable app_tags {
  description = "tags for instance"
  default = ["docker-machine"]
}
