terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "zoocamp-project-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- ATIVAÇÃO DE APIS ---
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# --- PERMISSÕES IAM ---
# Unificado: Apenas uma declaração com o depends_on
resource "google_service_account_iam_member" "allow_github_to_use_compute_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/198485878590-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-tf@zoocamp-project.iam.gserviceaccount.com"

  depends_on = [google_project_service.iam_api]
}

# --- DATA LAKE (STORAGE) ---
resource "google_storage_bucket" "data_lake" {
  name                        = var.data_lake_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# --- BIGQUERY ---
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bigquery_dataset
  project    = var.project_id
  location   = var.location
}

resource "google_bigquery_table" "exchange_rates" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "exchange_rates"
  project    = var.project_id

  schema = jsonencode([
    { name = "date",            type = "DATE",  mode = "REQUIRED" },
    { name = "base_currency",   type = "STRING", mode = "REQUIRED" },
    { name = "target_currency", type = "STRING", mode = "REQUIRED" },
    { name = "rate",            type = "FLOAT",  mode = "REQUIRED" }
  ])

  deletion_protection = false
}

# --- COMPUTE ENGINE (AIRFLOW VM) ---
resource "google_compute_instance" "airflow_vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["airflow"]

  service_account {
    scopes = ["cloud-platform"]
  }

  # Garante que a permissão de IAM seja aplicada ANTES da VM tentar subir
  depends_on = [google_service_account_iam_member.allow_github_to_use_compute_sa]
}

# --- FIREWALL ---
resource "google_compute_firewall" "allow_airflow" {
  name    = "allow-airflow-ui"
  network = "default"
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["airflow"]
}