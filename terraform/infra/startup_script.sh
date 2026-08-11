#!/bin/bash
set -e

# Atualiza pacotes e instala dependências
apt-get update -y
apt-get install -y python3-pip python3-venv ca-certificates sudo curl
update-ca-certificates

# --- Descobre valores dinamicamente (sem hardcode) ---
PROJECT_ID="$(curl -s -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/project/project-id")"
GCS_BUCKET="${PROJECT_ID}-data-lake"
BQ_DATASET="frankfurter_dev"

# Cria o diretório base e o usuário airflow (se não existirem)
mkdir -p /opt/airflow
useradd -m -s /bin/bash airflow || true
chown -R airflow:airflow /opt/airflow

# --- Executa o restante como usuário airflow para evitar erros de permissão ---
sudo -u airflow bash << EOF
set -e
export AIRFLOW_HOME=/opt/airflow

# Cria ambiente virtual dentro da pasta com permissão
python3 -m venv