terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {
  project_id = var.project_id
}

# --- DATA LAKE (STORAGE) ---
resource "google_storage_bucket" "data_lake" {
  name                        = "${var.project_id}-data-lake"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# --- BIGQUERY ---
resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.bigquery_dataset
  project                    = var.project_id
  location                   = var.location
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "exchange_rates" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "exchange_rates"
  project    = var.project_id

  schema = jsonencode([
    { name = "date", type = "DATE", mode = "REQUIRED" },
    { name = "base_currency", type = "STRING", mode = "REQUIRED" },
    { name = "target_currency", type = "STRING", mode = "REQUIRED" },
    { name = "rate", type = "FLOAT", mode = "REQUIRED" }
  ])

  deletion_protection = false
}

# ---------------------------------------------------------------------------
# GKE Autopilot cluster para rodar Airflow (Helm) + dbt (KubernetesPodOperator)
# ---------------------------------------------------------------------------
resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_container_cluster" "airflow_gke" {
  name     = "${var.project_id}-airflow-gke"
  location = var.region

  enable_autopilot = true

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network    = "default"
  subnetwork = "default"

  deletion_protection = false

  depends_on = [google_project_service.container]
}

resource "google_service_account" "airflow_gke_sa" {
  project      = var.project_id
  account_id   = "airflow-gke-sa"
  display_name = "Airflow (GKE) Service Account"
}

resource "google_project_iam_member" "airflow_gke_sa_bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.airflow_gke_sa.email}"
}

resource "google_project_iam_member" "airflow_gke_sa_bigquery_job" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.airflow_gke_sa.email}"
}

resource "google_project_iam_member" "airflow_gke_sa_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.airflow_gke_sa.email}"
}

resource "google_service_account_iam_member" "airflow_gke_sa_workload_identity" {
  service_account_id = google_service_account.airflow_gke_sa.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.project_id}.svc.id.goog[airflow/airflow]"
}