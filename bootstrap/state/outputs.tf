output "bucket_name" {
  description = "Nome do bucket criado para guardar o terraform state"
  value       = google_storage_bucket.terraform_state.bucket
}
