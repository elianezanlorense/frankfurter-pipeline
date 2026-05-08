
#!/bin/bash

set -e

GITHUB_REPOSITORY=$(grep github_repository terraform.tfvars | cut -d'"' -f2)

PROJECT=$(terraform output -raw project_id)

BUCKET=$(terraform output -raw bucket_name)

SA=$(terraform output -raw terraform_runner_sa_email)

WIF=$(terraform output -raw workload_identity_provider)

gh secret set GCP_PROJECT_ID   --repo $GITHUB_REPOSITORY --body "$PROJECT"

gh secret set GCP_TF_BUCKET    --repo $GITHUB_REPOSITORY --body "$BUCKET"

gh secret set GCP_SA_EMAIL     --repo $GITHUB_REPOSITORY --body "$SA"

gh secret set GCP_WIF_PROVIDER --repo $GITHUB_REPOSITORY --body "$WIF"

gh secret set SSH_PRIVATE_KEY --repo $GITHUB_REPOSITORY < ~/.ssh/airflow_vm

gh secret set SSH_PUBLIC_KEY  --repo $GITHUB_REPOSITORY < ~/.ssh/airflow_vm.pub

gcloud config set project "$PROJECT"

echo " Project: $PROJECT | Repo: $GITHUB_REPOSITORY"

