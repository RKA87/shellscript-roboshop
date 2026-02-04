#!/bin/bash

#Color Code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/catalogue.log"

SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws88s.online

#Check the user account has root privileges
ID=$(id -u)
if [ $ID -ne 0 ]; then
  echo -e "$RED You should be a root user to execute this script $NOCOLOR"
  exit 1
fi

mkdir -p /app

#Status Check Function
STAT_CHECK() {
  if [ $1 -ne 0 ]; then
    echo -e "$RED $2 FAILURE $NOCOLOR"
    echo -e "$YELLOW Check the log file for more information $NOCOLOR"
    exit 1
  else
    echo -e "$GREEN $2 ..SUCCESS.. $NOCOLOR"
  fi
}

dnf module disable nodejs -y &>>$LOG_FILE
STAT_CHECK $? "Disable Nodejs Module"

#Check Nodejs is already installed or not

if dnf list installed nodejs &>>$LOG_FILE; then
  echo -e "${YELLOW}Nodejs is already installed $NOCOLOR" | tee -a $LOG_FILE
else
  dnf module enable nodejs:24 -y &>>$LOG_FILE
  dnf install nodejs -y &>>$LOG_FILE
  STAT_CHECK $? "Installing Nodejs"
fi

id roboshop
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  STAT_CHECK $? "Adding Roboshop User"
else
  echo -e "$YELLOW Roboshop user already exists$NOCOLOR" | tee -a $LOG_FILE
fi

mkdir -p /app

#Create App Directory and download the code
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE

cd /app
STAT_CHECK $? "Changing Directory to /app"

rm -rf /app/*
STAT_CHECK $? "Remove exist app code from /app Directory"

unzip /tmp/catalogue.zip &>>$LOG_FILE
STAT_CHECK $? "Unzipping Catalogue Code" 

npm install &>>$LOG_FILE
STAT_CHECK $? "Installing Nodejs Dependencies"

#Configure the backend service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
STAT_CHECK $? "Copying Catalogue Service File"

systemctl daemon-reload
STAT_CHECK $? "Daemon Reload system service"

systemctl enable catalogue &>>$LOG_FILE
STAT_CHECK $? "Enabling Catalogue Service"

systemctl start catalogue &>>$LOG_FILE
STAT_CHECK $? "Starting Catalogue Service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE

#Update the MongoDB Endpoint in Catalogue Service File
INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    echo -e "$RED mongodb catalogue index data is not exist and executing the app data now $NOCOLOR}" | tee -a $LOG_FILE
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    STAT_CHECK  $? "Loading products into Mongodb using Catalogue"
else
    echo -e "$GREEN mongodb catalogue index data is already exist hence skipping the app data loading $NOCOLOR" | tee -a $LOG_FILE
fi

systemctl restart catalogue &>>$LOG_FILE
STAT_CHECK $? "Restarting Catalogue Service"