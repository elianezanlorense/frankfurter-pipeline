"""
Backfill script for Frankfurter exchange rates.
Fetches historical data using the date range endpoint and loads to BigQuery + GCS.

Usage:
    python backfill_exchange_rates.py --start 2024-01-01 --end 2024-12-31
    python backfill_exchange_rates.py --start 2024-01-01  # end defaults to today
"""

import argparse
import json
import requests
from datetime import date, datetime
from google.cloud import bigquery, storage

# ── Config ────────────────────────────────────────────────────────────────────
PROJECT_ID   = "frankfurter-pipeline"
DATASET      = "frankfurter_dev"
TABLE        = "exchange_rates"
BUCKET_NAME  = "frankfurter-data-lake-dev"
TABLE_ID     = f"{PROJECT_ID}.{DATASET}.{TABLE}"
# ─────────────────────────────────────────────────────────────────────────────


def fetch_range(start: str, end: str) -> dict:
    """Fetch all exchange rates between start and end date (inclusive)."""
    url = f"https://api.frankfurter.app/{start}..{end}"
    print(f"Fetching: {url}")
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    return response.json()


def save_to_gcs(data: dict, start: str, end: str) -> None:
    """Save raw JSON response to GCS."""
    client = storage.Client(project=PROJECT_ID)
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"raw/exchange_rates/backfill_{start}_{end}.json")
    blob.upload_from_string(json.dumps(data))
    print(f"Saved raw data to GCS: raw/exchange_rates/backfill_{start}_{end}.json")


def build_rows(data: dict) -> list:
    """
    Convert the range API response into a flat list of rows.

    API response format:
    {
        "amount": 1.0,
        "base": "EUR",
        "start_date": "2024-01-01",
        "end_date": "2024-12-31",
        "rates": {
            "2024-01-02": {"AUD": 1.67, "BRL": 5.40, ...},
            "2024-01-03": {...},
            ...
        }
    }
    """
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
    """Remove rows that already exist in BigQuery (by date + target_currency)."""
    if not rows:
        return []

    dates = list({r["date"] for r in rows})
    dates_str = ", ".join(f"'{d}'" for d in dates)

    query = f"""
        SELECT DISTINCT date, target_currency
        FROM `{TABLE_ID}`
        WHERE date IN ({dates_str})
    """
    existing = {(r.date.isoformat(), r.target_currency) for r in client.query(query).result()}

    if existing:
        print(f"Found {len(existing)} existing rows — skipping duplicates.")

    return [r for r in rows if (r["date"], r["target_currency"]) not in existing]


def load_to_bigquery(rows: list) -> None:
    """Insert rows into BigQuery in batches of 500."""
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
    parser = argparse.ArgumentParser(description="Backfill Frankfurter exchange rates into BigQuery.")
    parser.add_argument("--start", required=True, help="Start date (YYYY-MM-DD), min: 1999-01-04")
    parser.add_argument("--end",   default=date.today().isoformat(), help="End date (YYYY-MM-DD), default: today")
    args = parser.parse_args()

    # Validate dates
    try:
        start = datetime.strptime(args.start, "%Y-%m-%d").date()
        end   = datetime.strptime(args.end,   "%Y-%m-%d").date()
    except ValueError:
        raise ValueError("Dates must be in YYYY-MM-DD format")

    if start < date(1999, 1, 4):
        raise ValueError("Frankfurter API only has data from 1999-01-04")
    if start > end:
        raise ValueError("--start must be before --end")

    print(f"Backfilling exchange rates from {start} to {end}")

    # Fetch, save, and load
    data = fetch_range(str(start), str(end))
    save_to_gcs(data, str(start), str(end))
    rows = build_rows(data)
    print(f"Built {len(rows)} rows from API response")
    load_to_bigquery(rows)


if __name__ == "__main__":
    main()