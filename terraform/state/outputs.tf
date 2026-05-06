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
  value = "projects/${google_project.my_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github.workload_identity_pool_provider_id}"
}