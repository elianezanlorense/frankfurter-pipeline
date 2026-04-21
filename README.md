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

### GCP Setup

```bash
gcloud services enable cloudresourcemanager.googleapis.com --project=zoocamp-project

gcloud auth application-default login
gcloud auth application-default set-quota-project zoocamp-project
```

Get project number:

```bash
gcloud projects describe zoocamp-project --format="value(projectNumber)"
```

---

### . SSH Key for Airflow VM

```bash
ssh-keygen -t rsa -b 4096 -C "airflow-vm" -f ~/.ssh/airflow_vm -N ""
cat ~/.ssh/airflow_vm.pub
```

---

###  GitHub Secrets

Login:

```bash
gh auth login
```

Set secrets:

```bash
gh secret set GCP_CREDENTIALS < key.json
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
