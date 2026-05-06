gcloud projects create valida-zoocamp --name="valida-zoocamp"
gcloud billing accounts list
gcloud billing projects link valida-zoocamp --billing-account=01D180-1A236B-7BC5DB

gcloud services enable \
  compute.googleapis.com \
  bigquery.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iamcredentials.googleapis.com \
  --project=valida-zoocampgcloud services enable \
  compute.googleapis.com \
  bigquery.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iamcredentials.googleapis.com \
  --project=valida-zoocamp

cd terraform/state
terraform init
terraform plan
terraform apply

terraform output
bucket_name = "valida-zoocamp-tf-state"
terraform_runner_sa_email = "github-actions-tf@valida-zoocamp.iam.gserviceaccount.com"
workload_identity_provider = "projects/948484036275/locations/global/workloadIdentityPools/valida-zoocamp-github-pool-2/providers/valida-zoocamp-gh"
update bucket
  backend "gcs" {
    bucket = "valida-zoocamp-tf-state"
    prefix = "terraform/state"
  }
gh auth login
gh secret set SSH_PUBLIC_KEY < ~/.ssh/zoocamp_rsa.pub
gh secret set SSH_PRIVATE_KEY < ~/.ssh/zoocamp_rsa  
gh secret list

cd terraform/infra
terraform init
terraform apply -var="ssh_public_key=$(cat ~/.ssh/zoocamp_rsa.pub)"

gcloud config get-value project

gcloud storage buckets list --project=valida-zoocamp

gcloud config set project valida-zoocamp
terraform init