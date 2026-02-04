#!/bin/bash

#color code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

LOG_DIR="/var/log/shellscript-roboshop"
LOG_FILE="$LOG_DIR/nginix.log"
SCRIPT_DIR=$(pwd)

#check user root acc access
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo privileges${NOCOLOR}"
  exit 1
fi

mkdir -p $LOG_DIR

#status check function
STAT_CHECK() {
  if [ $1 -eq 0 ]; then
    echo -e "$GREEN $2 SUCCESS $NOCOLOR"
  else
    echo -e "$RED FAILURE $NOCOLOR"
    echo -e "$YELLOW Refer log file for more information: $LOG_FILE $NOCOLOR"
    exit 1
  fi
}

dnf module disbable nginx -y &>>$LOG_FILE
STAT_CHECK $? "Disabling Nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
STAT_CHECK $? "Enabling Nginx 1.24 module"

dnf install nginx -y &>>$LOG_FILE
STAT_CHECK $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
STAT_CHECK $? "Enabling Nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
STAT_CHECK $? "Removing default Nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
STAT_CHECK $? "Downloading frontend content"

cd /usr/share/nginx/html &>>$LOG_FILE
unzip /tmp/frontend.zip &>>$LOG_FILE
STAT_CHECK $? "Extracting frontend content"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
STAT_CHECK $? "Removing default Nginx configuration file"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
STAT_CHECK $? "Copying Nginx configuration file"

systemctl restart nginx &>>$LOG_FILE
STAT_CHECK $? "Restarting Nginx service"