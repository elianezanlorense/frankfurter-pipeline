gcloud billing projects list 
 gcloud billing projects unlink
 ls -l script/terraform-setup.shchmod +x

gcloud projects list

gcloud auth application-default set-quota-project frankfurter-pipeline
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  bigquery.googleapis.com \
  iam.googleapis.com

  # 1. Criar a Service Account
gcloud iam service-accounts create github-actions-sa \
  --display-name="GitHub Actions Service Account"

SERVICE_ACCOUNT_EMAIL="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts keys create key.json \
  --iam-account="$SERVICE_ACCOUNT_EMAIL" \
  --project="$PROJECT_ID"

 gcloud iam service-accounts keys create key.json \
  --iam-account="github-actions@${PROJECT_ID}.iam.gserviceaccount.com" 

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



verde onde esta sendo criado
grep -RIn --exclude-dir=.terraform "zoocamp-project" .

  --include="*.tf" \
  --include="*.tfvars" \
  --include="*.yml" \
  --include="*.yaml" \
  --include="*.sh" \
  --exclude-dir=.git
./terraform/infra/main.tf:18:  region  = var.region
./terraform/infra/main.tf:105:  location = var.region
./terraform/infra/main.tf:128:  location = var.region
./terraform/infra/main.tf:220:  location      = var.region
./terraform/infra/variables.tf:9:  default     = "europe-west1"
./terraform/infra/variables.tf:15:  default     = "europe-west1-b"
./terraform/state/state.tf:14:  region  = var.region
./terraform/state/variables.tf:8:  default = "europe-west1"
./.github/workflows/airflow.yml:19:      REGION: europe-west1
./.github/workflows/airflow.yml:45:          gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
./.github/workflows/airflow.yml:50:          IMAGE="${REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/dbt-images/airflow:${{ github.sha }}"
./.github/workflows/airflow.yml:82:            --region "$REGION" \
./.github/workflows/airflow.yml:100:                --region "$REGION" \
./.github/workflows/airflow.yml:173:            --set images.airflow.repository="${REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/dbt-images/airflow" \
./.github/workflows/dbt.yml:75:        run: gcloud auth configure-docker europe-west1-docker.pkg.dev --quiet
./.github/workflows/dbt.yml:80:          IMAGE="europe-west1-docker.pkg.dev/${GCP_PROJECT_ID}/dbt-images/dbt:${{ github.sha }}"
./.github/workflows/dbt.yml:81:          docker build -t "$IMAGE" -t "europe-west1-docker.pkg.dev/${GCP_PROJECT_ID}/dbt-images/dbt:latest" .
./.github/workflows/dbt.yml:88:          docker push "europe-west1-docker.pkg.dev/${GCP_PROJECT_ID}/dbt-images/dbt:latest"