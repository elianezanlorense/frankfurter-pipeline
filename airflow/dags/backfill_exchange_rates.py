import argparse
import json
import requests
from datetime import date, datetime
from google.cloud import bigquery, storage

# ── Config Sincronizada ──────────────────────────────────────────────────────
PROJECT_ID   = "zoocamp-project"
DATASET      = "frankfurter_dev"
TABLE        = "exchange_rates"
BUCKET_NAME  = "frankfurter-dl"
TABLE_ID     = f"{PROJECT_ID}.{DATASET}.{TABLE}"
# ─────────────────────────────────────────────────────────────────────────────

def fetch_range(start: str, end: str) -> dict:
    """Busca o intervalo completo na API."""
    url = f"https://api.frankfurter.app/{start}..{end}"
    print(f"Fetching: {url}")
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.json()

def save_to_gcs(data: dict, start: str, end: str) -> None:
    """Salva o JSON bruto no Storage."""
    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"raw/exchange_rates/backfill_{start}_{end}.json")
    blob.upload_from_string(json.dumps(data))
    print(f"Saved raw data to GCS: raw/exchange_rates/backfill_{start}_{end}.json")

def build_rows(data: dict) -> list:
    """Transforma o JSON aninhado em lista de dicionários (rows)."""
    rows = []
    base = data["base"]
    for date_str, currencies in data["rates"].items():
        for currency, rate in currencies.items():
            rows.append({
                "date": date_str,
                "base_currency": base,
                "target_currency": currency,
                "rate": rate,
            })
    return rows

def deduplicate(client: bigquery.Client, rows: list) -> list:
    """Evita duplicidade: remove o que já existe no BigQuery."""
    if not rows:
        return []

    dates = list({r["date"] for r in rows})
    dates_str = ", ".join(f"'{d}'" for d in dates)

    query = f"""
        SELECT DISTINCT date, target_currency
        FROM `{TABLE_ID}`
        WHERE date IN ({dates_str})
    """
    try:
        existing = {(r.date.isoformat(), r.target_currency) for r in client.query(query).result()}
    except Exception:
        # Se a tabela ainda não existir, não há o que deduplicar
        return rows

    if existing:
        print(f"Found {len(existing)} existing rows — skipping duplicates.")

    return [r for r in rows if (r["date"], r["target_currency"]) not in existing]

def load_to_bigquery(rows: list) -> None:
    """Insere no BigQuery usando batches de 500 para estabilidade."""
    if not rows:
        print("No new rows to insert.")
        return

    client = bigquery.Client(project=PROJECT_ID)
    rows = deduplicate(client, rows)

    if not rows:
        print("All rows already exist in BigQuery. Nothing to insert.")
        return

    batch_size = 500
    total_inserted = 0

    for i in range(0, len(rows), batch_size):
        batch = rows[i : i + batch_size]
        errors = client.insert_rows_json(TABLE_ID, batch)
        if errors:
            raise Exception(f"BigQuery insert errors: {errors}")
        total_inserted += len(batch)
        print(f"Inserted batch {i // batch_size + 1} — {total_inserted}/{len(rows)} rows")

    print(f"✅ Done! Loaded {total_inserted} rows into {TABLE_ID}")

def main():
    parser = argparse.ArgumentParser(description="Backfill Frankfurter exchange rates.")
    parser.add_argument("--start", required=True, help="YYYY-MM-DD")
    parser.add_argument("--end",   default=date.today().isoformat(), help="YYYY-MM-DD")
    args = parser.parse_args()

    # Validação básica de datas
    start_dt = datetime.strptime(args.start, "%Y-%m-%d").date()
    end_dt   = datetime.strptime(args.end,   "%Y-%m-%d").date()

    print(f"Iniciando backfill de {start_dt} até {end_dt}")

    data = fetch_range(str(start_dt), str(end_dt))
    save_to_gcs(data, str(start_dt), str(end_dt))
    
    rows = build_rows(data)
    print(f"Built {len(rows)} rows from API response")
    
    load_to_bigquery(rows)

if __name__ == "__main__":
    main()