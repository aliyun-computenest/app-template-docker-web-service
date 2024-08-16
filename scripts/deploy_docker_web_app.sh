#!/bin/bash
set -v

export BASE_DIR=/opt/applicationmanager
export REGION=$1
export APP_SOURCE=$2
export FILE_URL=$3
export COMMIT_HASH=$4
export DB_URL=$5
export DB_PORT=$6
export DB_USER=$7
export DB_PASSWORD=$8

function prepare_directory() {
  mkdir -p $BASE_DIR/bin 
  mkdir -p BASE_DIR/download 
  mkdir -p BASE_DIR/application 
  mkdir -p BASE_DIR/logs 
  mkdir -p BASE_DIR/env 
  mkdir -p BASE_DIR/config
}

function set_version() {
  echo "start deploying application" | tee /opt/applicationmanager/logs/deploy.log
  if [ "${APP_SOURCE}" == "File" ]; then
    echo $FILE_URL > $BASE_DIR/config/version
  elif [ "${APP_SOURCE}" == "GitRepo" ]; then
    echo $COMMIT_HASH > $BASE_DIR/config/version
  elif [ "${APP_SOURCE}" == "Demo" ]; then
    echo "Demo" > $BASE_DIR/config/version
  fi
}

function save_database_config() {
  cat > $BASE_DIR/env/database.env <<EOF
    DATABASE_HOST=${DB_URL}
    DATABASE_PORT=${DB_PORT}
    DATABASE_USERNAME=${DB_USER}
    DATABASE_PASSWORD=${DB_PASSWORD}
EOF
}

function download_source_bundle() {
  TOKEN=$(curl -X PUT "http://100.100.100.200/latest/api/token" -H "X-aliyun-ecs-metadata-token-ttl-seconds:600")
  ROLE_NAME=$(curl -H "X-aliyun-ecs-metadata-token: $TOKEN" http://100.100.100.200/latest/meta-data/ram/security-credentials/)
  ossutil -e oss-${REGION}.aliyuncs.com --mode EcsRamRole --ecs-role-name $ROLE_NAME cp $FILE_URL $BASE_DIR/download/
  FILE_NAME=$(basename $FILE_URL)
  rm -rf $BASE_DIR/application.old && mv $BASE_DIR/application $BASE_DIR/application.old
  mkdir -p $BASE_DIR/application && unzip $BASE_DIR/download/$FILE_NAME -d $BASE_DIR/application
}

function setup_docker_app() {
  systemctl stop docker-compose-app
  cat > /etc/systemd/system/docker-compose-app.service <<EOF
    [Unit]
    Description=Docker compose application deployed by application manager
    Requires=docker.service
    After=docker.service

    [Service]
    Type=oneshot
    RemainAfterExit=yes
    WorkingDirectory=$BASE_DIR/application
    ExecStart=/usr/bin/docker compose up -d
    ExecStop=/usr/bin/docker compose down
    TimeoutStartSec=0

    [Install]
    WantedBy=multi-user.target
EOF
systemctl enable docker-compose-app
systemctl start docker-compose-app
}

function main() {
  prepare_directory
  set_version
  save_database_config
  download_source_bundle
  setup_docker_app
}

set -v
main
