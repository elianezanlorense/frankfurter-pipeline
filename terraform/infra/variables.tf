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

variable "data_lake_bucket_name" {
  type    = string
  default = "frankfurter-dl"
}

variable "bigquery_dataset" {
  type    = string
  default = "frankfurter_dev"
}