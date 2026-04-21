# Frankfurter Pipeline
gh secret set GCP_CREDENTIALS < key.json

gcloud services enable cloudresourcemanager.googleapis.com --project=zoocamp-project

gcloud auth application-default login
gcloud auth application-default set-quota-project zoocamp-project
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub

gh auth login
gh secret set SSH_PRIVATE_KEY < ~/.ssh/airflow_vm
gh secret set SSH_PUBLIC_KEY < ~/.ssh/airflow_vm.pub
gh secret list

gcloud compute instances describe airflow-vm \
  --zone=europe-west1-b \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'


  echo "teste_airflow" > validacao.txt
gsutil cp validacao.txt gs://frankfurter-dl/
bq query --use_legacy_sql=false 'SELECT 1'
bq load --source_format=CSV --autodetect raw_data.exchange_rates gs://frankfurter-dl/validacao.txt


gcloud projects describe zoocamp-project --format="value(projectNumber)"