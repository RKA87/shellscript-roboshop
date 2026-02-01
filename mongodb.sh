#!/bin/bash

USER_ID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log"

#Color Coding
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# Check the user account priveleges
if [ $USER_ID -ne 0 ]; then
  echo -e "$RED You should run this script as root user or with sudo privileges $RESET"
  exit 1
fi

# Create logs directory if not exists
mkdir -p $LOGS_DIR

#status check function to validate the installation status
VALIDATE(){
    if [$1 -ne 0]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOGS_FILE
    fi
}
cp mongo.repo /etc/yum.repos.d/mongo.repo |tee -a $LOGS_FILE
VALIDATE $? "Copying MongoDB Repo File"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling MongoDB Service"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Starting MongoDB Service"

systemctl status mongod &>>$LOGS_FILE
VALIDATE $? "Checking MongoDB Service Status"

sed -i '/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOGS_FILE
VALIDATE $? "Allowing Remote Connections in MongoDB"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB Service"

systemctl status mongod &>>$LOGS_FILE
VALIDATE $? "Checking MongoDB Service Status After Restart"
