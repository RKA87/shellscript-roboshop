#!/bin/bash

#Color Coding
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

SCRIPT_DIR=$(pwd)
MONGODB_NAME=mongodb.rkak87.online

USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
    echo -n "you should be a root user account priveligies to run this script"
    exit 1
fi

LOG_DIR=/var/log/shellscript-roboshop
if [ ! -d $LOG_DIR ]; then
        echo -n "Creating log directory"
        mkdir -p $LOG_DIR
    else
        echo -n "log directory already exists"
fi

LOG_FILE="$LOG_DIR/catalogue.log"

# Status Check Function to validate the installation status
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS Module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20 Module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

if id roboshop &>>$LOG_FILE; then
    echo -e "$YELLOW roboshop user already exists $RESET" | tee -a $LOG_FILE
else
    echo -e "$GREEN Creating roboshop user $RESET"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system account" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop User"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating Application Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip | tee -a $LOG_FILE
VALIDATE $? "Downloading Catalogue Application Code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Extracting Catalogue Application Code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing NodeJS Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copying Catalogue SystemD Service File and creating catalogue.service"

systemctl daemon-reload

systemctl enable catalogue

systemctl start catalogue.service
VALIDATE $? "Starting Catalogue Service"

systemctl status catalogue.service
validate $? "Catalogue Service Status"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE #need to give absolute path in CP command
VALIDATE $? "Copying MongoDB Repo File"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb Shell"

#first check the database catalogue records, every database index is starts with 1
INDEX_CHECK=$(mongosh --host $MONGODB_NAME --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')" | tail -1)

if [ $INDEX_CHECK -le 0 ]; then
    echo -e "$YELLOW Catalogue Database is not present, we are creating the database $RESET" | tee -a $LOG_FILE
    mongosh --host $MONGODB_NAME </app/db/master-data.js
    VALIDATE $? "Loading Catalogue Data into Mongodb Database"
else
    echo -e "$YELLOW Catalogue Database is already present, we are skipping the database creation $RESET" | tee -a $LOG_FILE
fi

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarting Catalogue Service"

ss -lntp | grep 8080 &>>$LOG_FILE
curl http://localhost:8080/health &>>$LOG_FILE
VALIDATE $? "Validating Catalogue Service Listening Port"