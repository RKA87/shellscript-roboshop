#!/bin/bash

#color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"
SCRIPT_DIR=$(pwd)

#CHECK ROOT USER ACCESS
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo access${NOCOLOR}"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/payment.log"

# Function to log messages
STAT_CHECK() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}$2 ... SUCCESS ${NOCOLOR}"
  else
    echo -e "${RED}$2 ... FAILED ${NOCOLOR}"
    exit 1
  fi
}

#create system account for application
id roboshop &>/dev/null
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  STAT_CHECK $? "Creating system user 'roboshop'"
else
  echo -e "${GREEN}User 'roboshop' already exists${NOCOLOR}"
fi

# Check python3 is installed
dnf install python3 gcc python3-devel -y &>>$LOG_FILE
STAT_CHECK $? "Installing Python"

#create application directory and download the application code
mkdir -p /app &>>$LOG_FILE
STAT_CHECK $? "Creating application directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
STAT_CHECK $? "Downloading payment application code"

cd /app &>>$LOG_FILE
STAT_CHECK $? "Changing directory to /app"

rm -rf /app/*
STAT_CHECK $? "Remove exist app code from /app Directory"

unzip /tmp/payment.zip &>>$LOG_FILE
STAT_CHECK $? "Extracting payment application code"

#Install application dependencies
cd /app &>>$LOG_FILE
pip3 install -r requirements.txt &>>$LOG_FILE
STAT_CHECK $? "Installing application dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
STAT_CHECK $? "Copying payment systemd service file"

#systemctl services
systemctl daemon-reload &>>$LOG_FILE
STAT_CHECK $? "Reloading systemd daemon"

systemctl enable payment &>>$LOG_FILE
STAT_CHECK $? "Enabling payment service"

systemctl start payment &>>$LOG_FILE
STAT_CHECK $? "Starting payment service"