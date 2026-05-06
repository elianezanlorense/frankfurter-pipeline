terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "valida-zoocamp-tf-state"
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

# --- PERMISSÕES IAM (ATUALIZADO) ---

# Permissão para GitHub Actions
resource "google_service_account_iam_member" "allow_github_to_use_compute_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-tf@${var.project_id}.iam.gserviceaccount.com"
}

# Permissão para VM escrever no Storage (Resolve erro save_to_gcs)
resource "google_project_iam_member" "vm_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Permissão para VM carregar dados no BigQuery (Resolve erro load_to_bigquery)
resource "google_project_iam_member" "vm_bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "vm_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
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
    { name = "date",            type = "DATE",   mode = "REQUIRED" },
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

  metadata = {
    ssh-keys = "${var.ssh_user}:${var.ssh_public_key}"
  }

  metadata_startup_script = file("${path.module}/startup_script.sh")

  service_account {
    email  = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.ssh_key
    ]
  }

  depends_on = [google_service_account_iam_member.allow_github_to_use_compute_sa]
}

resource "terraform_data" "ssh_key" {
  input = var.ssh_public_key
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