output "bucket_name" {
  value = google_storage_bucket.terraform_state.name
}

output "project_id" {
  value = local.project_id
}

output "terraform_runner_sa_email" {
  value = google_service_account.terraform_runner.email
}

output "workload_identity_provider" {
  # Isso retorna o caminho completo e formatado automaticamente pelo GCP
  value = google_iam_workload_identity_pool_provider.github.name
}