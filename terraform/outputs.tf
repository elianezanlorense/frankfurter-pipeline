output "data_lake_bucket" {
  value = google_storage_bucket.data_lake.name
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.dataset.dataset_id
}

output "airflow_vm_name" {
  value = google_compute_instance.airflow_vm.name
}

output "airflow_vm_external_ip" {
  value = google_compute_instance.airflow_vm.network_interface[0].access_config[0].nat_ip
}