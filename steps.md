gcloud auth application-default set-quota-project frankfurter-pipeline
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  bigquery.googleapis.com \
  iam.googleapis.com

  # 1. Criar a Service Account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"


  # Atribuir roles necessárias
gcloud projects add-iam-policy-binding frankfurter-pipeline \
  --member="serviceAccount:github-actions-sa@frankfurter-pipeline.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding frankfurter-pipeline \
  --member="serviceAccount:github-actions-sa@frankfurter-pipeline.iam.gserviceaccount.com" \
  --role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding frankfurter-pipeline \
  --member="serviceAccount:github-actions-sa@frankfurter-pipeline.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

  gcloud iam service-accounts keys create ~/frankfurter-pipeline-key.json \
  --iam-account=github-actions-sa@frankfurter-pipeline.iam.gserviceaccount.com


  # Adicionar a chave como secret no GitHub
gh secret set GCP_SA_KEY < ~/frankfurter-pipeline-key.json

# Adicionar o project ID como secret
gh secret set GCP_PROJECT_ID --body="frankfurter-pipeline"


gh workflow run bootstrap.yml --ref infra_rebuild