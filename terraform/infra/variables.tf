variable "project_id" {
  type    = string
  default = "zoocamp-project"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "location" {
  type    = string
  default = "EU"
}

variable "data_lake_bucket_name" {
  type = string
  default = "frankfurter-dl"
}

variable "bigquery_dataset" {
  type = string
  default = "frankfurter_dev"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "vm_name" {
  type    = string
  default = "airflow-vm"
}

variable "vm_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "vm_image" {
  type    = string
  default = "debian-cloud/debian-12"
}

variable "vm_disk_size" {
  type    = number
  default = 20
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key" {
  type    = string
  default = ""
}