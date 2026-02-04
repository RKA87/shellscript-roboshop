#!/bin/bash

#Color Code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NO="\e[0m"

#Check user is root or not
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should be logged in as root user to execute this script${NO}"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/mongodb.log"

#Function to print status of the executed command
STAT_CHECK() {
  if [ $1 -ne 0 ]; then
    echo -e "${RED}FAILURE${NO}" | tee -a $LOG_FILE
    echo -e "${YELLOW}Refer the log file for more information: $LOG_FILE${NO}"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NO}" | tee -a $LOG_FILE
  fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
STAT_CHECK $? "Adding Mongodb Repo"

#check the mongodb server is already installed or not

if dnf list mongodb-org -y; then
  echo -e "${YELLOW}Mongodb is already installed${NO}" | tee -a $LOG_FILE
else
  dnf install -y mongodb-org | tee -a $LOG_FILE
  STAT_CHECK $? "Installing Mongodb"
fi

systemctl enable mongod &>>$LOG_FILE
STAT_CHECK $? "Enabling Mongodb Service"

systemctl start mongod &>>$LOG_FILE
STAT_CHECK $? "Starting Mongodb Service"

#Allow remote connections from /etc/mongod.conf
sed 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
STAT_CHECK $? "Allowing Remote Connections"

systemctl restart mongod &>>$LOG_FILE
STAT_CHECK $? "Restarting Mongodb Service"