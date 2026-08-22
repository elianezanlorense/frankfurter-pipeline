# 🚀 Frankfurter Pipeline

##  Objective

gcloud config get-value project
 cluster name:gcloud container clusters list \
  --region europe-west1 \
  --project zoocamp-project-914584
connect with cluster:
  gcloud container clusters get-credentials \
  zoocamp-project-914584-airflow-gke \
  --region europe-west1 \
  --project zoocamp-project-914584

  

K8s acess:
kubectl get nodes

# Confirm the current cluster/context
kubectl config current-context

# List namespaces
kubectl get namespaces

# View all running workloads
kubectl get pods --all-namespaces

# Check Airflow resources
kubectl get pods,services,deployments,statefulsets --all-namespaces | grep -i airflow

kubectl get jobs,pods -n airflow

POD=$(kubectl get pods -n airflow -o name | grep airflow-scheduler | head -n 1)
echo "$POD"

kubectl get "$POD" -n airflow -o jsonpath='{.spec.initContainers[*].name}{"\n"}'

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

--- terraform init -backend-config="bucket=zoocamp-project-660101-tf-state" testar no terminalter

##  Setup & Reproducibility
```
bash set-up-branch.sh
bash bootstrap.sh
```
### . SSH Key for Airflow VM

```bash
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub
#verify that created 
ls -l ~/.ssh/airflow_vm*
```

```bash
bash github-secrets-setup.sh
tt
```

Check:

```bash
gh secret list
```

---ip

##  Terraform Bootstrap

```bash
bash terraform-setup.sh

```
---
gcloud config get-value account
PROJECT_ID="$(gcloud config get-value project)"
echo "$PROJECT_ID"
bq ls --project_id="$PROJECT_ID"
bq ls "$PROJECT_ID:frankfurter_dev"

sudo python3 -m venv /opt/airflow/dbt_venv
sudo chown -R airflow:airflow /opt/airflow/dbt_venv
sudo -u airflow /opt/airflow/dbt_venv/bin/pip install dbt-bigquery
Cria o venv em /opt/airflow/dbt_venv
Transfere a posse da pasta pro usuário airflow
Instala o dbt-bigquery dentro desse venv, já como usuário airflow
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
