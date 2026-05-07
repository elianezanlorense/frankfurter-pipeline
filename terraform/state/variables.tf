variable "region" {
  type    = string
  default = "europe-west1"
}

variable "billing_account" {
  description = "O ID da conta de faturamento (ex: 01A2B3-C4D5E6-F7G8H9)"
  type        = string
}

variable "location" {
  type    = string
  default = "EU"
}

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