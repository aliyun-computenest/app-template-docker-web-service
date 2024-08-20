#!/bin/bash
ACTION=$1
echo "ACTION: $ACTION"
APP_SOURCE=$2
echo "APP_SOURCE: $APP_SOURCE"
FILE_URL=$3
echo "FILE_URL: $FILE_URL"
GIT_URL=$4
echo "GIT_URL: $GIT_URL"
COMMIT_HASH=$5
echo "COMMIT_HASH: $COMMIT_HASH"
DB_URL=$6
echo "DB_URL: $DB_URL"
DB_PORT=$7
echo "DB_PORT: $DB_PORT"
DB_USER=$8
echo "DB_USER: $DB_USER"
DB_PASSWORD=$9

function check_update() {
  if [ "$ACTION" == "UPDATE" ]; then
    if [ ! -e $BASE_DIR/version ]; then
      echo "first time installation is still running, skip update"
      exit 0
    fi
    version=$(cat $BASE_DIR/version)
    echo "version: $version"
    if [ "${APP_SOURCE}" == "File" ] && [ "${FILE_URL}" == "$version" ]; then
      echo "Found same oss file url, skip update" 
      exit 0
    fi
    if [ "${APP_SOURCE}" == "GitRepo" ] && [ "${COMMIT_HASH}" == "$version" ]; then
      echo "Found same git commit hash, skip update" 
      exit 0
    fi
    if [ "${APP_SOURCE}" == "Demo" ] && [ "Demo" == "$version" ]; then
      echo "Already deployed demo application, skip update" 
      exit 0
    fi
    echo "start updating application"
  fi
}

function prepare_directory() {
  echo "make application directories"
  mkdir -p $BASE_DIR/bin
  mkdir -p $BASE_DIR/download
  mkdir -p $BASE_DIR/logs
  mkdir -p $BASE_DIR/env
}

function set_version() {
  echo "start deploying application, set application version"
  if [ "${APP_SOURCE}" == "File" ]; then
    echo $FILE_URL>$BASE_DIR/version
  elif [ "${APP_SOURCE}" == "GitRepo" ]; then
    echo $COMMIT_HASH>$BASE_DIR/version
  elif [ "${APP_SOURCE}" == "Demo" ]; then
    echo "Demo">$BASE_DIR/version
  fi
}

function save_database_config() {
  if [ "${DB_URL}" != "" ]; then
    echo "save database configuration to env file"
    cat >$BASE_DIR/env/database.env <<EOF
DATABASE_HOST=${DB_URL}
DATABASE_PORT=${DB_PORT}
DATABASE_USERNAME=${DB_USER}
DATABASE_PASSWORD=${DB_PASSWORD}
EOF
  fi
}

function download_source_bundle() {
  if [ -d $BASE_DIR/application.old ]; then
    rm -rf $BASE_DIR/application.old
  fi
  if [ -d $BASE_DIR/application ]; then
    mv $BASE_DIR/application $BASE_DIR/application.old
  fi
  mkdir -p $BASE_DIR/application && cd $BASE_DIR/application

  if [ "${APP_SOURCE}" == "File" ]; then
    echo "download zip file from oss and extract it"
    TOKEN=$(curl -X PUT "http://100.100.100.200/latest/api/token" -H "X-aliyun-ecs-metadata-token-ttl-seconds:600")
    ROLE_NAME=$(curl -H "X-aliyun-ecs-metadata-token: $TOKEN" http://100.100.100.200/latest/meta-data/ram/security-credentials/)
    ossutil -e oss-cn-hangzhou.aliyuncs.com --mode EcsRamRole --ecs-role-name $ROLE_NAME cp $FILE_URL $BASE_DIR/download/
    FILE_NAME=$(basename $FILE_URL)
    unzip $BASE_DIR/download/$FILE_NAME -d $BASE_DIR/application
  elif [ "${APP_SOURCE}" == "GitRepo" ]; then
    echo "clone git repository to local"
    git clone --recurse-submodules --remote-submodules $GIT_URL $BASE_DIR/application
    git checkout $COMMIT_HASH
  elif [ "${APP_SOURCE}" == "Demo" ]; then
    echo "download demo application source boundle"
    wget -O $BASE_DIR/download/demo.zip https://applicationmanager-public-cn-hangzhou.oss-cn-hangzhou.aliyuncs.com/docker-web-service-demo.zip
    unzip $BASE_DIR/download/demo.zip -d $BASE_DIR/application
  fi
}

function setup_docker_app() {
  systemctl stop docker-web-service-app
  echo "setup system service and enable auto startup"
  cat >/etc/systemd/system/docker-web-service-app.service <<EOF
    [Unit]
    Description=docker web service deployed by application manager
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
  systemctl enable docker-web-service-app
  echo "start application service"
  systemctl start docker-web-service-app
}

function main() {
  check_update
  prepare_directory
  set_version
  save_database_config
  download_source_bundle
  setup_docker_app
}

main
