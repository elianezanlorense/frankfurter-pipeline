from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import json
from google.cloud import storage

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def fetch_exchange_rates(**context):
    date = context['ds']  # data de execução
    url = f"https://api.frankfurter.app/{date}"
    response = requests.get(url)
    data = response.json()
    return data

def save_to_gcs(**context):
    data = context['task_instance'].xcom_pull(task_ids='fetch_rates')
    date = context['ds']

    client = storage.Client()
    bucket = client.bucket('frankfurter-data-lake-dev')
    blob = bucket.blob(f'raw/exchange_rates/{date}.json')
    blob.upload_from_string(json.dumps(data))
    print(f"Saved data for {date} to GCS")

with DAG(
    'frankfurter_exchange_rates',
    default_args=default_args,
    description='Fetch exchange rates from Frankfurter API',
    schedule_interval='@daily',
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

    fetch_rates >> save_rates
