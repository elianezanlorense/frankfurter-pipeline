#!/bin/bash
set -e

# Atualiza pacotes e instala dependências
apt-get update -y
apt-get install -y python3-pip python3-venv ca-certificates sudo
update-ca-certificates

# Cria o diretório base e o usuário airflow (se não existirem)
mkdir -p /opt/airflow
useradd -m -s /bin/bash airflow || true
chown -R airflow:airflow /opt/airflow

# --- Executa o restante como usuário airflow para evitar erros de permissão ---
sudo -u airflow bash << 'EOF'
set -e
export AIRFLOW_HOME=/opt/airflow

# Cria ambiente virtual dentro da pasta com permissão
python3 -m venv /opt/airflow/venv
source /opt/airflow/venv/bin/activate

# Instala Airflow e dependências
pip install --upgrade pip
pip install apache-airflow==2.9.1 \
  apache-airflow-providers-google \
  requests

# Cria diretório de DAGs
mkdir -p /opt/airflow/dags

# Inicializa o banco de dados
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=False
airflow db init

# Cria usuário admin
airflow users create \
  --username admin \
  --password admin \
  --firstname Admin \
  --lastname Admin \
  --role Admin \
  --email admin@example.com
EOF

# Configura variáveis de ambiente globais para o usuário airflow
echo "export AIRFLOW_HOME=/opt/airflow" >> /home/airflow/.bashrc
echo "export PATH=/opt/airflow/venv/bin:$PATH" >> /home/airflow/.bashrc

# --- Criação dos serviços systemd (como root) ---
cat > /etc/systemd/system/airflow-webserver.service << EOF
[Unit]
Description=Airflow Webserver
After=network.target

[Service]
User=airflow
Group=airflow
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
Group=airflow
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

# Inicia os serviços
systemctl daemon-reload
systemctl enable airflow-webserver airflow-scheduler
systemctl start airflow-webserver airflow-scheduler