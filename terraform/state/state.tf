terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Gera o sufixo aleatório para garantir que o ID do projeto seja único no mundo
resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  project_id = "zoocamp-${random_id.suffix.hex}"
}

# CRIAÇÃO DO PROJETO
resource "google_project" "my_project" {
  name            = local.project_id
  project_id      = local.project_id
  billing_account = var.billing_account
}

# BUCKET DE ESTADO
resource "google_storage_bucket" "terraform_state" {
  name                        = "${local.project_id}-tf-state"
  project                     = google_project.my_project.project_id
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [google_project.my_project]
}

resource "google_project_service" "iam_credentials" {
  project = local.project_id
  service = "iamcredentials.googleapis.com"

  # Recomendado para APIs críticas para não interromper o CI/CD acidentalmente
  disable_on_destroy = false
}

# SERVICE ACCOUNT
resource "google_service_account" "terraform_runner" {
  project      = google_project.my_project.project_id
  account_id   = "github-actions-tf"
  display_name = "GitHub Actions Terraform Runner"
}

# PERMISSÕES IAM (Ajustadas para referenciar o recurso do projeto)
resource "google_project_iam_member" "terraform_permissions" {
  for_each = toset([
    "roles/compute.instanceAdmin.v1",
    "roles/compute.securityAdmin",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.workloadIdentityPoolAdmin"
  ])

  project = google_project.my_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform_runner.email}"
}

# WORKLOAD IDENTITY POOL
resource "google_iam_workload_identity_pool" "github" {
  project                   = google_project.my_project.project_id
  workload_identity_pool_id = "${local.project_id}-github-pool-2"
  display_name              = "GitHub Actions Pool"

  depends_on = [google_project_service.iam_credentials]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = google_project.my_project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "${local.project_id}-gh"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"
}

# MEMBER DO WIF (Ajustado para usar o número do projeto criado dinamicamente)
resource "google_service_account_iam_member" "github_wif_user" {
  service_account_id = google_service_account.terraform_runner.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${google_project.my_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}