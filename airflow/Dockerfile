# Imagem customizada do Airflow: parte da imagem oficial e adiciona os
# providers/libs que as DAGs precisam (requests, google-cloud-*, e o
# provider do Kubernetes, necessário para o KubernetesPodOperator).
FROM apache/airflow:2.9.1-python3.11

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir \
    -r /requirements.txt \
    apache-airflow-providers-cncf-kubernetes \
    apache-airflow-providers-google