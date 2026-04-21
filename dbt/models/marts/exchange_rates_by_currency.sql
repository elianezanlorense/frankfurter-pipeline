with base as (
    select
        target_currency,
        rate
    from {{ ref('stg_exchange_rates') }}
)
select
    target_currency,
    AVG(rate) as avg_rate,
    MIN(rate) as min_rate,
    MAX(rate) as max_rate,
    COUNT(*) as total_records
from base
group by target_currency
order by avg_rate desc
