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
git switch main
git pull origin main
git switch -c test


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
source ~/.bashrc
to verify all alias 
git config --global --get-regexp '^alias\.'

## Virtual envirioment
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv --version
uv sync
source .venv/bin/activate

# GCP 
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
gcloud auth list

PROJECT_ID="zoocamp-project-$(shuf -i 100000-999999 -n 1)"
gcloud projects create "$PROJECT_ID" --name="$PROJECT_ID"



# 5. Configurar o projeto de quota das credenciais
gcloud config set project "$PROJECT_ID"

gcloud auth application-default set-quota-project "$PROJECT_ID"

gcloud services enable cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID"

PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format="value(projectNumber)")"

echo "Project ID: $PROJECT_ID"
echo "Project number: $PROJECT_NUMBER"

# 6. Ativar a API necessária
gcloud services enable cloudresourcemanager.googleapis.com \
  --project="$PROJECT_ID"

# 7. Obter o número do projeto
PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format="value(projectNumber)")"

echo "Project ID: $PROJECT_ID"
echo "Project number: $PROJECT_NUMBER"
```

---

### . SSH Key for Airflow VM

```bash
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub
```
verify that created 
ls -l ~/.ssh/airflow_vm*
---

###  GitHub Secrets

Login:

```bash
gh auth login
gh api user --jq '.login'
git config user.name
git config user.email
```
unset GITHUB_TOKEN
gh auth login --hostname github.com --git-protocol https --scopes repo,workflow
gh auth status



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

terraform init
terraform fmt
terraform plan -var="github_repository=elianezanlorense/frankfurter-pipeline"
terraform apply -var="github_repository=elianezanlorense/frankfurter-pipeline"
```

---

## Main Infrastructure

```bash
cd ../infra

terraform init -reconfigure
terraform fmt
terraform plan
terraform apply
```

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
