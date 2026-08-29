import argparse
import json
import os
from datetime import date, datetime

import google.auth
import requests
from google.api_core.exceptions import NotFound
from google.cloud import bigquery, storage


# ---------------------------------------------------------------------------
# Configuração
# ---------------------------------------------------------------------------

try:
    PROJECT_ID = os.environ["GCP_PROJECT_ID"]
except KeyError:
    _, PROJECT_ID = google.auth.default()

if not PROJECT_ID:
    raise RuntimeError(
        "Não foi possível identificar o projeto GCP. "
        "Configure a variável GCP_PROJECT_ID."
    )

DATASET = os.environ["BQ_DATASET"]
TABLE = os.environ.get("BQ_TABLE", "exchange_rates")
BUCKET_NAME = os.environ["GCS_BUCKET"]

TABLE_ID = f"{PROJECT_ID}.{DATASET}.{TABLE}"


# ---------------------------------------------------------------------------
# Extração
# ---------------------------------------------------------------------------

def fetch_range(start: str, end: str) -> dict:
    """Busca as taxas de câmbio para um intervalo de datas."""

    url = f"https://api.frankfurter.app/{start}..{end}"

    print(f"Fetching: {url}")

    response = requests.get(url, timeout=30)
    response.raise_for_status()

    data = response.json()

    if not data:
        raise ValueError("A API retornou uma resposta vazia.")

    if "base" not in data:
        raise ValueError("A resposta da API não contém o campo 'base'.")

    if "rates" not in data:
        raise ValueError("A resposta da API não contém o campo 'rates'.")

    return data


# ---------------------------------------------------------------------------
# Cloud Storage
# ---------------------------------------------------------------------------

def save_to_gcs(
    data: dict,
    start: str,
    end: str,
) -> None:
    """Salva a resposta original da API no Cloud Storage."""

    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(BUCKET_NAME)

    object_name = (
        f"raw/exchange_rates/backfill_{start}_{end}.json"
    )

    blob = bucket.blob(object_name)

    blob.upload_from_string(
        json.dumps(data),
        content_type="application/json",
    )

    print(
        f"Saved raw data to "
        f"gs://{BUCKET_NAME}/{object_name}"
    )


# ---------------------------------------------------------------------------
# Transformação
# ---------------------------------------------------------------------------

def build_rows(data: dict) -> list[dict]:
    """Transforma a resposta da API em linhas para o BigQuery."""

    rows = []
    base_currency = data["base"]

    for date_str, currencies in data["rates"].items():
        for target_currency, rate in currencies.items():
            rows.append(
                {
                    "date": date_str,
                    "base_currency": base_currency,
                    "target_currency": target_currency,
                    "rate": rate,
                }
            )

    return rows


# ---------------------------------------------------------------------------
# Deduplicação
# ---------------------------------------------------------------------------

def deduplicate(
    client: bigquery.Client,
    rows: list[dict],
) -> list[dict]:
    """Remove linhas que já existem no BigQuery."""

    if not rows:
        return []

    dates = sorted(
        {
            date.fromisoformat(row["date"])
            for row in rows
        }
    )

    query = f"""
        SELECT DISTINCT
            date,
            target_currency
        FROM `{TABLE_ID}`
        WHERE date IN UNNEST(@dates)
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ArrayQueryParameter(
                "dates",
                "DATE",
                dates,
            )
        ]
    )

    try:
        query_job = client.query(
            query,
            job_config=job_config,
        )

        existing = {
            (
                row.date.isoformat(),
                row.target_currency,
            )
            for row in query_job.result()
        }

    except NotFound:
        print(
            f"Tabela {TABLE_ID} ainda não existe. "
            "Todas as linhas serão inseridas."
        )
        return rows

    if existing:
        print(
            f"Found {len(existing)} existing rows. "
            "Skipping duplicates."
        )

    new_rows = [
        row
        for row in rows
        if (
            row["date"],
            row["target_currency"],
        )
        not in existing
    ]

    return new_rows


# ---------------------------------------------------------------------------
# BigQuery
# ---------------------------------------------------------------------------

def load_to_bigquery(rows: list[dict]) -> None:
    """Insere as linhas no BigQuery em lotes."""

    if not rows:
        print("No rows received.")
        return

    client = bigquery.Client(project=PROJECT_ID)

    rows = deduplicate(client, rows)

    if not rows:
        print(
            "All rows already exist in BigQuery. "
            "Nothing to insert."
        )
        return

    batch_size = 500
    total_inserted = 0

    for start_index in range(
        0,
        len(rows),
        batch_size,
    ):
        batch = rows[
            start_index:start_index + batch_size
        ]

        errors = client.insert_rows_json(
            TABLE_ID,
            batch,
        )

        if errors:
            raise RuntimeError(
                f"BigQuery insert errors: {errors}"
            )

        total_inserted += len(batch)
        batch_number = (
            start_index // batch_size
        ) + 1

        print(
            f"Inserted batch {batch_number}: "
            f"{total_inserted}/{len(rows)} rows"
        )

    print(
        f"Done! Loaded {total_inserted} rows "
        f"into {TABLE_ID}"
    )


# ---------------------------------------------------------------------------
# Validação dos argumentos
# ---------------------------------------------------------------------------

def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Backfill das taxas de câmbio "
            "da API Frankfurter."
        )
    )

    parser.add_argument(
        "--start",
        required=True,
        help="Data inicial no formato YYYY-MM-DD.",
    )

    parser.add_argument(
        "--end",
        default=date.today().isoformat(),
        help="Data final no formato YYYY-MM-DD.",
    )

    args = parser.parse_args()

    try:
        start_date = datetime.strptime(
            args.start,
            "%Y-%m-%d",
        ).date()

        end_date = datetime.strptime(
            args.end,
            "%Y-%m-%d",
        ).date()

    except ValueError:
        parser.error(
            "As datas devem estar no formato YYYY-MM-DD."
        )

    if start_date > end_date:
        parser.error(
            "--start não pode ser posterior a --end."
        )

    args.start_date = start_date
    args.end_date = end_date

    return args


# ---------------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------------

def main() -> None:
    args = parse_arguments()

    start = args.start_date.isoformat()
    end = args.end_date.isoformat()

    print(f"Project: {PROJECT_ID}")
    print(f"Bucket: {BUCKET_NAME}")
    print(f"BigQuery table: {TABLE_ID}")
    print(f"Starting backfill from {start} to {end}")

    data = fetch_range(start, end)

    save_to_gcs(
        data=data,
        start=start,
        end=end,
    )

    rows = build_rows(data)

    print(
        f"Built {len(rows)} rows "
        "from the API response."
    )

    load_to_bigquery(rows)


if __name__ == "__main__":
    main()