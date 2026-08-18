variable "project_id" {
  description = "Google Cloud project ID where resources will be created"
  type        = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "location" {
  type    = string
  default = "EU"
}

variable "github_repository" {
  type = string
}

variable "workload_identity_pool_id" {
  type    = string
  default = "github-pool"
}

variable "workload_identity_provider_id" {
  type    = string
  default = "github-provider"
}