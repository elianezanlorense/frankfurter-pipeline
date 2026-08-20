output "data_lake_bucket" {
  value = google_storage_bucket.data_lake.name
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.dataset.dataset_id
}

output "bigquery_table" {
  value = google_bigquery_table.exchange_rates.table_id
}

output "gke_cluster_name" {
  value = google_container_cluster.airflow_gke.name
}

output "gke_cluster_location" {
  value = google_container_cluster.airflow_gke.location
}

output "gke_cluster_endpoint" {
  value     = google_container_cluster.airflow_gke.endpoint
  sensitive = true
}

output "airflow_gke_sa_email" {
  value = google_service_account.airflow_gke_sa.email
}