# Imagem usada pelo KubernetesPodOperator do Airflow para rodar `dbt run` e
# `dbt test` como pods isolados no cluster GKE.
FROM python:3.11-slim

RUN pip install --no-cache-dir dbt-bigquery

WORKDIR /dbt

# Copia o projeto dbt inteiro (models, seeds, macros, dbt_project.yml, etc.)
COPY . .

# profiles.yml não vai dentro da imagem (evita hardcode de config de
# ambiente na imagem). Ele é montado como ConfigMap/Volume no Kubernetes
# na hora que o pod sobe, apontando para este diretório.
ENV DBT_PROFILES_DIR=/root/.dbt

# Sem ENTRYPOINT/CMD fixo: o KubernetesPodOperator do Airflow passa o
# comando explicitamente (ex: ["dbt", "run", "--project-dir", "/dbt"]),
# então a imagem só precisa ter o dbt instalado e o projeto copiado.