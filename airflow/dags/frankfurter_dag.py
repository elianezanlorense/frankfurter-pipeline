import json
import os
from datetime import datetime, timedelta
from textwrap import dedent

import google.auth
import requests
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.pod import (
    KubernetesPodOperator,
)
from google.cloud import bigquery, storage


# ---------------------------------------------------------------------------
# Configurações
# ---------------------------------------------------------------------------

try:
    PROJECT_ID = os.environ["GCP_PROJECT_ID"]
except KeyError:
    _, PROJECT_ID = google.auth.default()

DATA_LAKE_BUCKET_NAME = os.environ["GCS_BUCKET"]
BIGQUERY_DATASET = os.environ["BQ_DATASET"]

TABLE_ID = f"{PROJECT_ID}.{BIGQUERY_DATASET}.exchange_rates"

DBT_IMAGE = os.environ.get(
    "DBT_IMAGE",
    (
        "europe-west4-docker.pkg.dev/"
        f"{PROJECT_ID}/dbt-images/dbt:latest"
    ),
)

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}


# ---------------------------------------------------------------------------
# Funções Python
# ---------------------------------------------------------------------------

def fetch_exchange_rates(**context):
    date = context["ds"]
    url = f"https://api.frankfurter.app/{date}"

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    data = response.json()

    if not data or "rates" not in data:
        raise ValueError(f"Resposta inválida para {date}")

    return data


def save_to_gcs(**context):
    data = context["task_instance"].xcom_pull(
        task_ids="fetch_rates"
    )
    date = context["ds"]

    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(DATA_LAKE_BUCKET_NAME)
    blob = bucket.blob(f"raw/exchange_rates/{date}.json")

    blob.upload_from_string(
        json.dumps(data),
        content_type="application/json",
    )


def load_to_bigquery(**context):
    date = context["ds"]
    data = context["task_instance"].xcom_pull(
        task_ids="fetch_rates"
    )

    client = bigquery.Client(project=PROJECT_ID)

    rows = [
        {
            "date": date,
            "base_currency": data["base"],
            "target_currency": currency,
            "rate": rate,
        }
        for currency, rate in data["rates"].items()
    ]

    errors = client.insert_rows_json(TABLE_ID, rows)

    if errors:
        raise RuntimeError(f"Erro ao inserir dados no BigQuery: {errors}")


# ---------------------------------------------------------------------------
# Comando dbt
# ---------------------------------------------------------------------------

def dbt_command(command):
    return dedent(
        f"""
        set -eu

        mkdir -p /tmp/dbt-profile

        cat > /tmp/dbt-profile/profiles.yml <<'EOF'
        zoocamp_project:
          target: dev
          outputs:
            dev:
              type: bigquery
              method: oauth
              project: {PROJECT_ID}
              dataset: {BIGQUERY_DATASET}
              location: EU
              threads: 2
        EOF

        dbt {command} \
          --project-dir /dbt \
          --profiles-dir /tmp/dbt-profile
        """
    ).strip()


# ---------------------------------------------------------------------------
# DAG
# ---------------------------------------------------------------------------

with DAG(
    dag_id="frankfurter_exchange_rates",
    default_args=default_args,
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["frankfurter", "gcp", "dbt"],
) as dag:

    fetch_rates = PythonOperator(
        task_id="fetch_rates",
        python_callable=fetch_exchange_rates,
    )

    save_rates = PythonOperator(
        task_id="save_to_gcs",
        python_callable=save_to_gcs,
    )

    load_bq = PythonOperator(
        task_id="load_to_bigquery",
        python_callable=load_to_bigquery,
    )

    dbt_run = KubernetesPodOperator(
        task_id="dbt_run",
        name="frankfurter-dbt-run",
        namespace="airflow",
        image=DBT_IMAGE,
        image_pull_policy="Always",
        service_account_name="airflow",
        cmds=["/bin/sh", "-c"],
        arguments=[dbt_command("run")],
        get_logs=True,
        in_cluster=True,
        startup_timeout_seconds=300,
        on_finish_action="delete_pod",
    )

    dbt_test = KubernetesPodOperator(
        task_id="dbt_test",
        name="frankfurter-dbt-test",
        namespace="airflow",
        image=DBT_IMAGE,
        image_pull_policy="Always",
        service_account_name="airflow",
        cmds=["/bin/sh", "-c"],
        arguments=[dbt_command("test")],
        get_logs=True,
        in_cluster=True,
        startup_timeout_seconds=300,
        on_finish_action="delete_pod",
    )

    fetch_rates >> save_rates >> load_bq >> dbt_run >> dbt_test