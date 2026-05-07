
after state


gh secret set GCP_TF_BUCKET \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "$(terraform output -raw bucket_name)"

gh secret set GCP_PROJECT_ID \
  --repo elianezanlorense/frankfurter-pipeline \'vali
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



# Atualizar secrets
gh secret set GCP_WIF_PROVIDER \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "projects/$(gcloud projects describe zoocamp-8d63 --format='value(projectNumber)')/locations/global/workloadIdentityPools/zoocamp-8d63-github-pool-2/providers/zoocamp-8d63-gh"

gh secret set GCP_SA_EMAIL \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "github-actions-tf@zoocamp-8d63.iam.gserviceaccount.com"

gh secret set GCP_PROJECT_ID \
  --repo elianezanlorense/frankfurter-pipeline \
  --body "zoocamp-8d63"

grep -A3 "backend" ./terraform/infra/main.tf


gh auth login
gh secret set SSH_PUBLIC_KEY < ~/.ssh/zoocamp_rsa.pub
gh secret set SSH_PRIVATE_KEY < ~/.ssh/zoocamp_rsa  

project_id 
gcloud projects list

gcloud iam workload-identity-pools list \
  --project=zoocamp-450e \
  --location=global


gcloud iam workload-identity-pools providers list \
  --project=zoocamp-450e  \
  --location=global \
  --workload-identity-pool=projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2

gh secret set GCP_WIF_PROVIDER \
  --body "$(gcloud iam workload-identity-pools providers describe meu-provider \
    --project=zoocamp-450e  \
    --location=global \
    --workload-identity-pool=projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2 \
    --format='value(rojects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2/providers/zoocamp-450e-gh)')"

  gh secret set GCP_WIF_PROVIDER \
  --body "projects/633690587904/locations/global/workloadIdentityPools/zoocamp-450e-github-pool-2/providers/zoocamp-450e-gh"

  grep -r "zoocamp-project-tf-state\|zoocamp-450e-tf-state" ./terraform/


  consultar bucket name
  terraform output -raw bucket_name
  grep "bucket" ./terraform/infra


  terraform output