# 🚀 Frankfurter Pipeline

##  Objective

This project builds an **end-to-end batch data pipeline** using exchange rate data from the Frankfurter API.

It covers:

* Data ingestion
* Data lake storage
* Data warehouse loading
* Transformations
* Dashboard visualization

---

## Problem Description

The goal is to analyze currency exchange rates over time and provide insights through a dashboard.

Key questions:

* How do exchange rates evolve over time?
* What is the distribution of currencies?
* Which currencies behave differently?

---

## 🏗️ Architecture

**Batch pipeline**

### Stack

* Cloud: GCP
* IaC: Terraform
* Orchestration: Airflow
* Data Lake: GCS
* Data Warehouse: BigQuery
* Transformations: dbt
* Dashboard: Looker Studio

---

##  Pipeline Flow

1. Extract data (Frankfurter API)
2. Store raw data in GCS (Data Lake)
3. Load into BigQuery
4. Transform with dbt
5. Visualize in dashboard

---

##  Project Structure

```
.
├── airflow/
├── dbt/
├── terraform/
│   ├── infra/
│   └── state/
├── README.md
```

---

##  Setup & Reproducibility

## Git 
git branch
git pull origin main
git switch -c test

# Alias
echo "alias st='git status'" >> ~/.bashrc
echo "alias sw='git switch'" >> ~/.bashrc
echo "alias br='git branch'" >> ~/.bashrc
echo "alias co='git checkout'" >> ~/.bashrc
echo "alias cm='git commit'" >> ~/.bashrc
echo "alias ps='git push'" >> ~/.bashrc
echo "alias pl='git pull'" >> ~/.bashrc
echo "alias ga='git add'" >> ~/.bashrc
echo "alias lg='git log --oneline --graph --decorate --all'" >> ~/.bashrc

source ~/.bashrc
# to verify all alias 
alias | grep git

## Virtual envirioment
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv init
export UV_LINK_MODE=copy
uv sync
source .venv/bin/activate

# Install GCP 
sudo apt-get update
sudo apt-get install -y ca-certificates gnupg curl

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get update
sudo apt-get install -y google-cloud-cli

gcloud version

### GCP Setup

```bash

gcloud auth login
gcloud auth application-default login

PROJECT_ID="zoocamp-project-$(shuf -i 100000-999999 -n 1)"
<<<<<<< HEAD
=======

gcloud projects create "$PROJECT_ID" \
  --name="$PROJECT_ID"
>>>>>>> a7d3e20 (update gcp auth)

gcloud projects create "$PROJECT_ID" --name="$PROJECT_ID"
gcloud config set project "$PROJECT_ID"

<<<<<<< HEAD
BILLING_ACCOUNT_ID="$(gcloud billing accounts list --filter="open=true" --format="value(ACCOUNT_ID)" --limit=1)"

gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"
gcloud beta billing projects describe "$PROJECT_ID"

gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com --project="$PROJECT_ID"

gcloud services list --enabled --project="$PROJECT_ID" --filter="config.name:compute.googleapis.com"

OAUTHLIB_RELAX_TOKEN_SCOPE=1 gcloud auth application-default login
gcloud auth application-default set-quota-project "$PROJECT_ID"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")"
=======
PROJECT_NUMBER="$(
  gcloud projects describe "$PROJECT_ID" \
    --format="value(projectNumber)"
)"

BILLING_ACCOUNT_ID="$(
  gcloud billing accounts list \
    --filter="open=true" \
    --format="value(name)" \
    --limit=1
)"

if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
  echo "Nenhuma conta de faturamento aberta encontrada." >&2
  exit 1
fi

gcloud billing projects link "$PROJECT_ID" \
  --billing-account="$BILLING_ACCOUNT_ID"

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  --project="$PROJECT_ID"

gcloud auth application-default set-quota-project "$PROJECT_ID"

export TF_VAR_project_id="$PROJECT_ID"
>>>>>>> a7d3e20 (update gcp auth)

echo "Project ID: $PROJECT_ID"
echo "Project number: $PROJECT_NUMBER"
echo "Billing account: $BILLING_ACCOUNT_ID"
<<<<<<< HEAD
=======

PROJECT_ID="$(gcloud config get-value project)"
SA_NAME="github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="$(mktemp)"

if ! gcloud iam service-accounts describe "$SA_EMAIL" \
  --project="$PROJECT_ID" >/dev/null 2>&1
then
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="GitHub Actions" \
    --project="$PROJECT_ID"
fi
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.bucketViewer"
gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL" \
  --project="$PROJECT_ID"

gh secret set GCP_CREDENTIALS < "$KEY_FILE"
gh variable set GCP_PROJECT_ID --body="$PROJECT_ID"

shred -u "$KEY_FILE"
unset KEY_FILE

gh secret list
gh variable list
>>>>>>> a7d3e20 (update gcp auth)
```
### . SSH Key for Airflow VM

```bash
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub
#verify that created 
ls -l ~/.ssh/airflow_vm*
```

---

###  GitHub Secrets

Login:

```bash
gh auth login
gh api user --jq '.login'
git config user.name
git config user.email
unset GITHUB_TOKEN
gh auth login --hostname github.com --git-protocol https --scopes repo,workflow
gh auth status
```




Set secrets:

```bash
gh secret set SSH_PRIVATE_KEY < ~/.ssh/airflow_vm
gh secret set SSH_PUBLIC_KEY < ~/.ssh/airflow_vm.pub
```

Check:

```bash
gh secret list
```

---

##  Terraform Bootstrap

```bash
wget -O - https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
cd terraform/state

export TF_VAR_project_id="$(gcloud config get-value project)"
export TF_VAR_github_repository="$(gh repo view --json nameWithOwner --jq '.nameWithOwner')"
terraform init
terraform fmt
terraform plan 
terraform apply 
```
gh secret set GCP_WIF_PROVIDER \
  --body "$(terraform -chdir=terraform/state output -raw workload_identity_provider)"

gh secret set GCP_SA_EMAIL \
  --body "$(terraform -chdir=terraform/state output -raw terraform_runner_sa_email)"

gh secret list --app actions

---

## Main Infrastructure

```bash
cd ../infra
export TF_VAR_ssh_public_key="$(cat ~/.ssh/airflow_vm.pub)"
terraform init -reconfigure \
  -backend-config="bucket=$TF_STATE_BUCKET"
terraform fmt
terraform plan
terraform apply
```

gh secret set GCP_WIF_PROVIDER \
  --body "$(terraform -chdir=terraform/state output -raw workload_identity_provider)"

gh secret set GCP_SA_EMAIL \
  --body "$(terraform -chdir=terraform/state output -raw terraform_runner_sa_email)"

gh secret list --app actions
---

##  Get VM IP

```bash
gcloud compute instances describe airflow-vm \
  --zone=europe-west1-b \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

---

## . Validate Pipeline

```bash
echo "teste_airflow" > validacao.txt

gsutil cp validacao.txt gs://frankfurter-dl/

bq query --use_legacy_sql=false 'SELECT 1'

bq load --source_format=CSV --autodetect raw_data.exchange_rates gs://frankfurter-dl/validacao.txt
```

---

## airflow

Airflow orchestrates:

* API extraction
* upload to GCS
* load to BigQuery

---

## Data Warehouse

BigQuery layers:

* raw_data
* staging
* marts

Tables should be:

* partitioned (by date)
* clustered (by currency)

---

##  Transformations

Using dbt:

```bash
cd dbt
dbt deps
dbt run
dbt test
```

---


Minimum 2 tiles:

1. Categorical distribution (currencies)
2. Temporal evolution (exchange rates over time)

---



##Notes

* If Terraform fails with "already exists", use:

```bash
terraform import
```

* If backend changes:

```bash
terraform init -reconfigure
```

---
