variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "location" {
  type = string
}

variable "bigquery_dataset" {
  type = string
}

variable "zone" {
  type = string
}

variable "vm_name" {
  type = string
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
  default = "airflow"
}

variable "ssh_public_key" {
  type = string
}