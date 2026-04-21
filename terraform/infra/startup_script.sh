#!/bin/bash
set -e

apt-get update -y
apt-get install -y python3-pip python3-venv ca-certificates
update-ca-certificates

# Cria usuário airflow
useradd -m -s /bin/bash airflow || true

# Cria ambiente virtual
python3 -m venv /opt/airflow/venv
source /opt/airflow/venv/bin/activate

# Instala Airflow e dependências
pip install --upgrade pip
pip install apache-airflow==2.9.1 \
  apache-airflow-providers-google \
  requests

# Cria diretório de DAGs
mkdir -p /opt/airflow/dags
chown -R airflow:airflow /opt/airflow

# Configura variáveis de ambiente
export AIRFLOW_HOME=/opt/airflow
echo "export AIRFLOW_HOME=/opt/airflow" >> /home/airflow/.bashrc
echo "export PATH=/opt/airflow/venv/bin:$PATH" >> /home/airflow/.bashrc

# Inicializa o banco de dados
sudo -u airflow bash -c "
  source /opt/airflow/venv/bin/activate
  export AIRFLOW_HOME=/opt/airflow
  export AIRFLOW__CORE__LOAD_EXAMPLES=False
  airflow db init
  airflow users create \
    --username admin \
    --password admin \
    --firstname Admin \
    --lastname Admin \
    --role Admin \
    --email admin@example.com
"

# Cria serviços systemd
cat > /etc/systemd/system/airflow-webserver.service << EOF
[Unit]
Description=Airflow Webserver
After=network.target

[Service]
User=airflow
Environment=AIRFLOW_HOME=/opt/airflow
Environment=AIRFLOW__CORE__LOAD_EXAMPLES=False
Environment=PATH=/opt/airflow/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/airflow/venv/bin/airflow webserver --port 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/airflow-scheduler.service << EOF
[Unit]
Description=Airflow Scheduler
After=network.target

[Service]
User=airflow
Environment=AIRFLOW_HOME=/opt/airflow
Environment=AIRFLOW__CORE__LOAD_EXAMPLES=False
Environment=AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=False
Environment=PATH=/opt/airflow/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStart=/opt/airflow/venv/bin/airflow scheduler
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable airflow-webserver airflow-scheduler
systemctl start airflow-webserver airflow-scheduler