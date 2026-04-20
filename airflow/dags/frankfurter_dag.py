from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import requests
import json
from google.cloud import storage, bigquery

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def fetch_exchange_rates(**context):
    date = context['ds']
    url = f"https://api.frankfurter.app/{date}"
    response = requests.get(url)
    data = response.json()
    return data  # ✅ indented inside function

def save_to_gcs(**context):
    data = context['task_instance'].xcom_pull(task_ids='fetch_rates')
    date = context['ds']
    client = storage.Client(project='zoocamp-project')
    bucket = client.bucket('frankfurter-dl"')
    blob = bucket.blob(f'raw/exchange_rates/{date}.json')
    blob.upload_from_string(json.dumps(data))
    print(f"Saved data for {date} to GCS")  # ✅ indented inside function

def load_to_bigquery(**context):  # ✅ moved outside the DAG block
    date = context['ds']
    data = context['task_instance'].xcom_pull(task_ids='fetch_rates')
    client = bigquery.Client(project='frankfurter-pipeline')
    rows = []
    for currency, rate in data['rates'].items():
        rows.append({
            'date': date,
            'base_currency': data['base'],
            'target_currency': currency,
            'rate': rate,
        })
    table_id = 'frankfurter-pipeline.frankfurter_dev.exchange_rates'
    errors = client.insert_rows_json(table_id, rows)
    if errors:
        raise Exception(f"BigQuery insert errors: {errors}")
    print(f"Loaded {len(rows)} rows to BigQuery for {date}")

with DAG(
    'frankfurter_exchange_rates',
    default_args=default_args,
    description='Fetch exchange rates from Frankfurter API',
    schedule='@daily',  # ✅ fixed deprecation warning too
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