#!/bin/bash

#Color Code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/cart.log"

SCRIPT_DIR=$PWD

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
    echo -e "$RED $2 FAILURE $NOCOLOR" | tee -a $LOG_FILE
    echo -e "$YELLOW Check the log file for more information $NOCOLOR"
    exit 1
  else
    echo -e "$GREEN $2 ..SUCCESS.. $NOCOLOR" | tee -a $LOG_FILE
  fi
}

dnf module disable nodejs -y &>>$LOG_FILE
STAT_CHECK $? "Disable Nodejs Module"

#Check Nodejs is already installed or not

if dnf list installed nodejs &>>$LOG_FILE; then
  echo -e "$YELLOW Nodejs is already installed $NOCOLOR" | tee -a $LOG_FILE
else
  dnf module enable nodejs:24 -y &>>$LOG_FILE
  dnf install nodejs -y &>>$LOG_FILE
  STAT_CHECK $? "Installing Nodejs"
fi

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  STAT_CHECK $? "Adding Roboshop User"
else
  echo -e "$YELLOW Roboshop user already exists$NOCOLOR" | tee -a $LOG_FILE
fi

mkdir -p /app
STAT_CHECK $? "Creating App Directory"

#Create App Directory and download the code
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$LOG_FILE

cd /app
STAT_CHECK $? "Changing Directory to /app"

rm -rf /app/*
STAT_CHECK $? "Remove exist app code from /app Directory"

unzip /tmp/cart.zip &>>$LOG_FILE
STAT_CHECK $? "Unzipping cart Code" 

npm install &>>$LOG_FILE
STAT_CHECK $? "Installing Nodejs Dependencies"

#Configure the backend service
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
STAT_CHECK $? "Copying cart Service File"

systemctl daemon-reload
STAT_CHECK $? "Daemon Reload system service"

systemctl enable cart &>>$LOG_FILE
STAT_CHECK $? "Enabling cart Service"

systemctl start cart &>>$LOG_FILE
STAT_CHECK $? "Starting cart Service"

systemctl restart cart &>>$LOG_FILE
STAT_CHECK $? "Restarting cart"