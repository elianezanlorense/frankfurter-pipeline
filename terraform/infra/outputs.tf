output "data_lake_bucket" {
  value = google_storage_bucket.data_lake.name
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.dataset.dataset_id
}

output "bigquery_table" {
  value = google_bigquery_table.exchange_rates.table_id
}