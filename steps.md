after terraform destroy
before 
gcloud billing accounts list - and past  terraform.tfvars
cd terraform/state
terraform init
terraform plan
terraform apply - yes

terraform output

secrets - 
gh secret set GCP_TF_BUCKET \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "$(terraform output -raw bucket_name)"

gh secret set GCP_PROJECT_ID \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "$(terraform output -raw project_id)"

gh secret set GCP_SA_EMAIL \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "$(terraform output -raw terraform_runner_sa_email)"

gh secret set GCP_WIF_PROVIDER \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "$(terraform output -raw workload_identity_provider)"

gh secret set SSH_PRIVATE_KEY \
  --repo elianezanlorense/frankfurter-pipeline \
  < ~/.ssh/airflow_vm

gh secret set SSH_PUBLIC_KEY \
  --repo elianezanlorense/frankfurter-pipeline \
  < ~/.ssh/airflow_vm.pub

  consultar bucket name
  terraform output -raw bucket_name
  grep "bucket" ./terraform/infra


  terraform output


  gcloud compute instances describe airflow-vm \
  --zone=europe-west1-b \
  --project=zoocamp-8d63 \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'