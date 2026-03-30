terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "frankfurter-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Data Lake
resource "google_storage_bucket" "data_lake" {
  name                        = var.data_lake_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# BigQuery
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bigquery_dataset
  project    = var.project_id
  location   = var.location
  delete_contents_on_destroy = true 
}

resource "google_bigquery_table" "exchange_rates" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "exchange_rates"
  project    = var.project_id

  schema = jsonencode([
    {
      name = "date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "base_currency"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "target_currency"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "rate"
      type = "FLOAT"
      mode = "REQUIRED"
    }
  ])

  deletion_protection = false
}