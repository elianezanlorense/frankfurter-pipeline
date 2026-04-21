# Frankfurter Pipeline
gh secret set GCP_CREDENTIALS < key.json

gcloud services enable cloudresourcemanager.googleapis.com --project=zoocamp-project

gcloud auth application-default login
gcloud auth application-default set-quota-project zoocamp-project
