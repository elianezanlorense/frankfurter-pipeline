variable "project_id" {
  description = "Google Cloud project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "Região dos recursos do Google Cloud"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zona do cluster GKE"
  type        = string
  default     = "europe-west1-b"
}

variable "location" {
  description = "Localização dos recursos do Google Cloud"
  type        = string
  default     = "EU"
}

variable "data_lake_bucket_name" {
  description = "Nome do bucket do Data Lake"
  type        = string
  default     = "frankfurter-dl"
}

variable "bigquery_dataset" {
  description = "Nome do dataset do BigQuery"
  type        = string
  default     = "frankfurter_dev"
}