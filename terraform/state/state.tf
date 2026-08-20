terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {
  project_id = var.project_id
}

# ---------------------------------------------------------------------------
# Terraform State
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.project_id}-tf-state"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}

# ---------------------------------------------------------------------------
# GitHub Actions Terraform Runner
# ---------------------------------------------------------------------------

resource "google_service_account" "terraform_runner" {
  project      = var.project_id
  account_id   = "github-actions-tf"
  display_name = "GitHub Actions Terraform Runner"
}

# ---------------------------------------------------------------------------
# Permissões de infraestrutura
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "terraform_compute_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

resource "google_project_iam_member" "terraform_compute_security_admin" {
  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

resource "google_project_iam_member" "terraform_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

resource "google_project_iam_member" "terraform_bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# ---------------------------------------------------------------------------
# Permissões IAM
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "terraform_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

resource "google_project_iam_member" "terraform_service_account_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# Necessária para usar Service Accounts em recursos como os nodes do GKE.
resource "google_project_iam_member" "terraform_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

resource "google_project_iam_member" "terraform_workload_identity_admin" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityPoolAdmin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# ---------------------------------------------------------------------------
# Service Usage
# Permite que o Terraform habilite APIs com google_project_service.
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "terraform_service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# ---------------------------------------------------------------------------
# Google Kubernetes Engine
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "terraform_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# ---------------------------------------------------------------------------
# Artifact Registry
# ---------------------------------------------------------------------------

resource "google_project_iam_member" "terraform_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# ---------------------------------------------------------------------------
# GitHub Actions Workload Identity Federation
# ---------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.project_id}-ghpool"
  display_name              = "GitHub Actions Pool"
  description               = "OIDC pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.project_id}-gh"
  display_name                       = "GitHub Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif_user" {
  service_account_id = google_service_account.terraform_runner.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/attribute.repository/${var.github_repository}"

  depends_on = [
    google_iam_workload_identity_pool_provider.github
  ]
}

# ---------------------------------------------------------------------------
# APIs gerenciadas pelo bootstrap
# ---------------------------------------------------------------------------

resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}