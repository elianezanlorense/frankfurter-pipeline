# get project id
gcloud config get-value project

gcloud storage ls
gs://zoocamp-project-225448-tf-state/

# autnetica 
gcloud auth application-default login


airflow_gke_sa_email = "airflow-gke-sa@zoocamp-project-225448.iam.gserviceaccount.com"
bigquery_dataset = "frankfurter_dev"
bigquery_table = "exchange_rates"
data_lake_bucket = "zoocamp-project-225448-data-lake"
gke_cluster_endpoint = <sensitive>
gke_cluster_location = "europe-west4-b"
gke_cluster_name = "zoocamp-project-225448-airflow-gke"

export CLUSTER_NAME="zoocamp-project-225448-airflow-gke"
export CLUSTER_ZONE="sua-nova-zona"

export CLUSTER_NAME="zoocamp-project-225448-airflow-gke"
export CLUSTER_ZONE="europe-west4-b"

gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project zoocamp-project-225448
kubectl get nodes

kubectl get secret airflow-git-ssh -n airflow


create namespace
sed 's/PROJECT_ID/zoocamp-project-225448/' k8s/namespace-sa.yaml | kubectl apply -f -

deploy manual:
ssh-keygen -t ed25519 -f /tmp/airflow-local-test -N "" -C "airflow-git-sync-local-test"


kubectl create configmap airflow-pipeline-config \
  --namespace airflow \
  --from-literal=GCP_PROJECT_ID="zoocamp-project-225448" \
  --from-literal=GCS_BUCKET="zoocamp-project-225448-data-lake" \
  --from-literal=BQ_DATASET="frankfurter_dev" \
  --from-literal=ARTIFACT_REGION="europe-west4" \
  --from-literal=AIRFLOW__LOGGING__REMOTE_LOGGING="True" \
  --from-literal=AIRFLOW__LOGGING__REMOTE_BASE_LOG_FOLDER="gs://zoocamp-project-225448-data-lake/airflow-logs" \
  --from-literal=AIRFLOW__LOGGING__REMOTE_LOG_CONN_ID="google_cloud_default" \
  --from-literal=AIRFLOW_CONN_GOOGLE_CLOUD_DEFAULT="google-cloud-platform://"

  kubectl get configmap airflow-pipeline-config -n airflow

  gcloud artifacts repositories list --project zoocamp-project-225448

  gcloud auth configure-docker europe-west4-docker.pkg.dev

  cd airflow
docker build --tag europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow:local-test 

> open -a Docker
> docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
> 

docker build --tag europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow:local-test .

docker push europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow:local-test

gcloud artifacts docker images list europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images

helm repo add apache-airflow https://airflow.apache.org --force-update
helm repo update

cd ..
helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --create-namespace \
  --version 1.19.0 \
  --values helm/airflow-values.yaml \
  --set-string images.airflow.repository="europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow" \
  --set-string images.airflow.tag="local-test" \
  --timeout 10m0s

kubectl describe pod airflow-webserver-7d4ffd8677-pcpr9 -n airflow | tail -30

cd airflow
docker build --platform linux/amd64 --tag europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow:local-test .


cd ..
helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow \
  --create-namespace \
  --version 1.19.0 \
  --values helm/airflow-values.yaml \
  --set-string images.airflow.repository="europe-west4-docker.pkg.dev/zoocamp-project-225448/dbt-images/airflow" \
  --set-string images.airflow.tag="local-test" \
  --timeout 10m0s


  kubectl get pods -n airflow

  kubectl logs airflow-webserver-5fc674678f-xlnpx -n airflow --container webserver --tail=40

  kubectl get pod airflow-scheduler-68d4978cdc-ldbq4 -n airflow -o jsonpath='{.spec.serviceAccountName}'