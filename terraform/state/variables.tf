variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "location" {
  type    = string
  default = "EU"
}

#variable "bucket_name" {
# type = string
#}



variable "github_repository" {
  type = string
  # exemplo: "seu-user-ou-org/seu-repo"
}

variable "workload_identity_pool_id" {
  type    = string
  default = "github-pool"
}

variable "workload_identity_provider_id" {
  type    = string
  default = "github-provider"
}