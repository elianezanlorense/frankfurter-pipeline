from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import json
from google.cloud import storage, bigquery

PROJECT_ID = "zoocamp-project"
DATA_LAKE_BUCKET_NAME = "frankfurter-dl"
BIGQUERY_DATASET = "frankfurter_dev"
TABLE_ID = f"{PROJECT_ID}.{BIGQUERY_DATASET}.exchange_rates"

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def fetch_exchange_rates(**context):
    date = context['ds']
    url = f"https://api.frankfurter.app/{date}"
    response = requests.get(url, timeout=30)
    response.raise_for_status()

    data = response.json()
    if not data or 'rates' not in data:
        raise ValueError(f"Invalid API response for date {date}: {data}")

    return data

def save_to_gcs(**context):
    data = context['task_instance'].xcom_pull(task_ids='fetch_rates')
    date = context['ds']

    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(DATA_LAKE_BUCKET_NAME)
    blob = bucket.blob(f'raw/exchange_rates/{date}.json')

    blob.upload_from_string(
        json.dumps(data),
        content_type='application/json'
    )
    print(f"Saved data for {date} to GCS")

def load_to_bigquery(**context):
    date = context['ds']
    data = context['task_instance'].xcom_pull(task_ids='fetch_rates')

    if not data or 'rates' not in data:
        raise ValueError(f"No valid exchange rate data found in XCom for {date}")

    client = bigquery.Client(project=PROJECT_ID)
    rows = []

    for currency, rate in data['rates'].items():
        rows.append({
            'date': date,
            'base_currency': data['base'],
            'target_currency': currency,
            'rate': rate,
        })

    errors = client.insert_rows_json(TABLE_ID, rows)
    if errors:
        raise Exception(f"BigQuery insert errors: {errors}")

    print(f"Loaded {len(rows)} rows to BigQuery for {date}")

with DAG(
    'frankfurter_exchange_rates',
    default_args=default_args,
    description='Fetch exchange rates from Frankfurter API',
    schedule='@daily',
    start_date=datetime(2024, 1, 1),
    catchup=False,
) as dag:

    fetch_rates = PythonOperator(
        task_id='fetch_rates',
        python_callable=fetch_exchange_rates,
    )

    save_rates = PythonOperator(
        task_id='save_to_gcs',
        python_callable=save_to_gcs,
    )

    load_bq = PythonOperator(
        task_id='load_to_bigquery',
        python_callable=load_to_bigquery,
    )

    fetch_rates >> save_rates >> load_bq