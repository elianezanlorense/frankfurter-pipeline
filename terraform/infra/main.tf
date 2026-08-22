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

# ---------------------------------------------------------------------------
# Data Lake — Cloud Storage
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "data_lake" {
  name                        = "${var.project_id}-data-lake"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# ---------------------------------------------------------------------------
# BigQuery
# ---------------------------------------------------------------------------

resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = var.bigquery_dataset
  project                    = var.project_id
  location                   = var.location
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "exchange_rates" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "exchange_rates"

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

# ---------------------------------------------------------------------------
# Google Kubernetes Engine
# Cluster Standard (não Autopilot) para Airflow e dbt com
# KubernetesPodOperator.
#
# NOTA: trocamos de Autopilot para Standard porque no free tier a cota de
# CPU costuma ser baixa (ex: 12 vCPUs no total, globalmente via
# CPUS_ALL_REGIONS) e não é aprovada para aumento automaticamente. O
# Autopilot escolhe nodes grandes por padrão (ex: e2-standard-8 = 8 vCPUs
# cada), estourando essa cota já com 2 nodes. No Standard controlamos o
# tamanho exato via node pool próprio, abaixo.
# ---------------------------------------------------------------------------

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_container_cluster" "airflow_gke" {
  project  = var.project_id
  name     = "${var.project_id}-airflow-gke"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network    = "default"
  subnetwork = "default"

  deletion_protection = false

  # A API do GKE precisa estar habilitada antes da criação do cluster.
  depends_on = [
    google_project_service.container
  ]
}

resource "google_container_node_pool" "airflow_gke_nodes" {
  name     = "airflow-pool"
  cluster  = google_container_cluster.airflow_gke.name
  location = var.zone
  project  = var.project_id

  # 2 nodes x e2-medium (2 vCPUs cada) = 4 vCPUs no mínimo, com folga
  # confortável dentro da cota de 12 vCPUs do free tier. Ajustar
  # node_count/machine_type depois de solicitar aumento de cota, se
  # necessário.
  node_count = 2

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 30
    disk_type    = "pd-standard"

    # necessário para os pods usarem Workload Identity (autenticação sem
    # chave JSON) neste node pool
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ---------------------------------------------------------------------------
# Service Account utilizada pelo Airflow no GKE
# ---------------------------------------------------------------------------

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

# Autoriza a Kubernetes Service Account airflow/airflow a utilizar
# a Google Service Account airflow-gke-sa.
resource "google_service_account_iam_member" "airflow_gke_sa_workload_identity" {
  service_account_id = google_service_account.airflow_gke_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[airflow/airflow]"

  # O pool PROJECT_ID.svc.id.goog só existe depois que o cluster GKE
  # com Workload Identity estiver completamente criado.
  depends_on = [
    google_container_cluster.airflow_gke
  ]
}

# ---------------------------------------------------------------------------
# Artifact Registry
# Repositório Docker para a imagem do dbt
# ---------------------------------------------------------------------------

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "dbt_images" {
  project       = var.project_id
  location      = var.region
  repository_id = "dbt-images"
  description   = "Imagens Docker do dbt, usadas pelo KubernetesPodOperator do Airflow"
  format        = "DOCKER"

  # A API precisa estar habilitada antes da criação do repositório.
  depends_on = [
    google_project_service.artifactregistry
  ]
}

# Permite que a Service Account do GitHub Actions faça push das imagens.
resource "google_artifact_registry_repository_iam_member" "github_actions_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.dbt_images.location
  repository = google_artifact_registry_repository.dbt_images.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:github-actions-tf@${var.project_id}.iam.gserviceaccount.com"
}

# Permite que os pods do GKE façam pull da imagem do dbt.
resource "google_artifact_registry_repository_iam_member" "airflow_gke_sa_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.dbt_images.location
  repository = google_artifact_registry_repository.dbt_images.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.airflow_gke_sa.email}"
}