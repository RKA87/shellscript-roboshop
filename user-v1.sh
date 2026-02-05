#!/bin/bash

#color code
RED="\e[31m"
GREEN="\e[32m"
NOCOLOR="\e[0m"
SCRIPT_DIR=$PWD

#Check if the script is run as root user
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo privileges${NOCOLOR}"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/user.log"

#Function to print status of the executed command
STAT_CHECK(){
    if [ $1 -ne 0 ]; then
      echo -e "${RED}$2 ... FAILURE${NC}" | tee -a "$LOG_FILE"
      echo -e "${YELLOW}Refer the log file for more information: $LOG_FILE${NO}"
      exit 1
    else
      echo -e "${GREEN}$2 ... SUCCESS${NC}" | tee -a "$LOG_FILE"
    fi
}

dnf module disable nodejs -y | tee -a $LOG_FILE

#Check the package is installed or not
if dnf list installed nodejs &>>$LOG_FILE; then
    echo -e "${GREEN}Nodejs is already installed${NOCOLOR}" | tee -a $LOG_FILE
else
    dnf module enable nodejs:24 -y | tee -a $LOG_FILE
    dnf install nodejs -y | tee -a $LOG_FILE
    STAT_CHECK $? "Installing Nodejs"
fi

#Check user roboshop exists or not

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    STAT_CHECK $? "Adding Roboshop User"
else
  echo -e "${GREEN}Roboshop user already exists${NOCOLOR}" | tee -a $LOG_FILE
fi

#Create application directory
mkdir -p /app
STAT_CHECK $? "Creating Application Directory"

#download code and unzip app code
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
STAT_CHECK $? "Downloading User Service Code"

cd /app
STAT_CHECK $? "Changing Directory to /app"

rm -rf /app/*
STAT_CHECK $? "Removing Existing Application Code"

unzip /tmp/user.zip &>>$LOG_FILE
STAT_CHECK $? "Extracting User Service Code"

npm install &>>$LOG_FILE
STAT_CHECK $? "Installing Nodejs Dependencies"

#configure the user systemctl service
cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
STAT_CHECK $? "Copying User Service File"

systemctl daemon-reload &>>$LOG_FILE
stat_CHECK $? "Reloading Systemd Services"

systemctl enable user &>>$LOG_FILE
STAT_CHECK $? "Enabling User Service"

systemctl start user &>>$LOG_FILE
STAT_CHECK $? "Starting User Service"
