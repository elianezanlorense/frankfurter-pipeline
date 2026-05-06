gh auth login
gh secret set SSH_PUBLIC_KEY < ~/.ssh/zoocamp_rsa.pub
gh secret set SSH_PRIVATE_KEY < ~/.ssh/zoocamp_rsa  
gh secret list
gh variable set GCP_PROJECT_ID --body "$(terraform output -raw project_id)"

gh variable set GCP_SA_EMAIL --body "$(terraform output -raw terraform_runner_sa_email)"

gh variable set GCP_WIF_PROVIDER --body "$(terraform output -raw workload_identity_provider)"
gh variable list

# Seta o Project ID
gh variable set GCP_PROJECT_ID --body "$(terraform output -raw project_id | tr -d '\r\n')"

# Seta o E-mail da Service Account (usando seu output terraform_runner_sa_email)
gh variable set GCP_SA_EMAIL --body "$(terraform output -raw terraform_runner_sa_email | tr -d '\r\n')"

# Seta o WIF Provider
gh variable set GCP_WIF_PROVIDER --body "$(terraform output -raw workload_identity_provider | tr -d '\r\n')"

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