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

# --- 1. BUSCA DINÂMICA DE DADOS ---
# Isso permite que o código funcione no projeto de qualquer revisor
data "google_project" "project" {}

# --- 2. PERMISSÕES IAM AUTOMATIZADAS ---
# Resolve o erro de Service Account User sem usar o seu número de projeto fixo
resource "google_service_account_iam_member" "allow_github_to_use_compute_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-tf@${var.project_id}.iam.gserviceaccount.com"
}

# --- 3. INFRAESTRUTURA (DATA LAKE & BQ) ---
resource "google_storage_bucket" "data_lake" {
  name                        = var.data_lake_bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bigquery_dataset
  project    = var.project_id
  location   = var.location
}

# --- 4. COMPUTE ENGINE (AIRFLOW VM) ---
resource "google_compute_instance" "airflow_vm" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size
    }
  }

  network_interface {
    network = "default"
    access_config {} # IP Público
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  # CRITICAL: Garante que a permissão de IAM acima aconteça ANTES da VM ser criada
  depends_on = [google_service_account_iam_member.allow_github_to_use_compute_sa]
}

# --- 5. FIREWALL ---
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