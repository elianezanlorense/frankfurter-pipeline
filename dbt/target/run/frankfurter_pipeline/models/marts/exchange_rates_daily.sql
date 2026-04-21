

  create or replace view `frankfurter-pipeline`.`frankfurter_dev`.`exchange_rates_daily`
  OPTIONS()
  as with base as (
    select
        date,
        base_currency,
        target_currency,
        rate
    from `frankfurter-pipeline`.`frankfurter_dev`.`stg_exchange_rates`
)
select
    date,
    base_currency,
    target_currency,
    rate,
    AVG(rate) OVER (
        PARTITION BY target_currency
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as rate_7day_avg
from base
order by date desc;

