terraform {
  backend "gcs" {
    bucket = "frankfurter-tf-state"
    prefix = "bootstrap/state"
  }
}
