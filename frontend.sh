#!/bin/bash

#Color Coding
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

SCRIPT_DIR=$(pwd)

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

LOG_FILE="$LOG_DIR/frontend.log"

# Status Check Function to validate the installation status
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOG_FILE
    fi
}

dnf module list nginx &>>$LOG_FILE
VALIDATE $? "Checking Nginx Module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx 1.24 Module"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx Service"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx Service"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Cleaning Nginx Default Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Frontend Application Code"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "Navigating to usr/share/nginx/html Directory"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting Frontend Application Code"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Removing Default Nginx Configuration File"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying Nginx Configuration File"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx Service"

ss -lntp | grep 80 &>>$LOG_FILE
curl http://localhost:80/health &>>$LOG_FILE
VALIDATE $? "Validating Frontend Service Listening Port"