

  create or replace view `zoocamp-project`.`frankfurter_dev`.`stg_exchange_rates`
  OPTIONS()
  as with source as (
    select
        date,
        base_currency,
        target_currency,
        rate
    from `zoocamp-project`.`frankfurter_dev`.`exchange_rates`
),
renamed as (
    select
        date,
        base_currency,
        target_currency,
        cast(rate as FLOAT64) as rate
    from source
)
select * from renamed;

