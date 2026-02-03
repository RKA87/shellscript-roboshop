#!/bin/bash

#Color Pattern
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"
SCRIPT_DIR=$(pwd)

#First Check user account has root priveliges
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo privileges"
  exit 1
else
  echo -e "${GREEN}User has root privileges, proceeding with the script execution...${RESET}"
fi

#Log Directory
LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR
echo "Log directory created"
LOG_FILE="$LOG_DIR/catalogue.log"

#Function to check the validation/status
VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOG_FILE
    fi
}



#Install NodeJS
if dnf list installed | grep nodejs; then
  echo -e "$YELLOW NodeJS is already installed on the system $RESET" | tee -a $LOG_FILE
else
  echo -e "$YELLOW NodeJS is not installed on the system we are proceeding with the installation $RESET" | tee -a $LOG_FILE
  dnf module disable nodejs - y &>>$LOG_FILE
  dnf module enable nodejs:24 -y &>>$LOG_FILE
  dnf install nodejs -y &>>$LOG_FILE
  VALIDATE $? "Installing NodeJS"
fi

#Add Application User
if id roboshop &>>$LOG_FILE; then
  echo -e "$YELLOW User roboshop already exists on the system $RESET" | tee -a $LOG_FILE
else
  echo -e "$YELLOW User roboshop does not exist on the system we are creating the user $RESET" | tee -a $LOG_FILE
  useradd roboshop &>>$LOG_FILE
  VALIDATE $? "Adding Application User"
fi

#Create Application Directory
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating Application Directory"

#Download the code
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue Code"

cd /app
rm -rf /app/*
unzip /tmp/catalogue.zip |tee -a $LOG_FILE
VALIDATE $? "Extracting Catalogue Code in App Directory"

#Install Dependencies
npm install &>>$LOG_FILE
VALIDATE $? "Installing NodeJS Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service |tee -a $LOG_FILE
VALIDATE $? "Copying Catalogue Service File into system directory"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading SystemD Daemon"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling Catalogue Service"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting Catalogue Service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo | tee -a $LOG_FILE
VALIDATE $? "Copying MongoDB Repo File"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB Shell"

INDEX=$(mongosh --host mongodb.rkaka87.online --quiet --eval 'db.getDBNames().indexOf("catalogue")')
if [ $INDEX -eq -1 ]; then
    mongosh --host mongodb.rkaka87.online --quiet < /app/db/master-data.js | tee -a $LOG_FILE
    VALIDATE $? "Loading Catalogue Data into MongoDB"
else
    echo -e "$YELLOW Catalogue Database is already present, So we are skipping the data loading step $RESET" | tee -a $LOG_FILE
fi

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarting Catalogue Service"