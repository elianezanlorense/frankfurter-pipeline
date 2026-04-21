# Frankfurter Pipeline
gh secret set GCP_CREDENTIALS < key.json

gcloud services enable cloudresourcemanager.googleapis.com --project=zoocamp-project

gcloud auth application-default login
gcloud auth application-default set-quota-project zoocamp-project
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub