variable project {
  description = "Project ID"
  default     = "docker-258208"
}
variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}
variable region {
  description = "Region"
  default     = "europe-west1"
}
variable cluster_name {
  description = "Name for the cluster"
  default     = "k8s-cluster"
}
variable pool_name {
  description = "Name for the node pool"
  default     = "node-pool"
}
variable machine_type {
  description = "Machine type for the node"
  default     = "g1-small"
}
variable node_count {
  description = "count of nodes"
  default     = 2
}
variable disable_dashboard {
  description = "Dashboard (Depricated)"
  default     = false
}