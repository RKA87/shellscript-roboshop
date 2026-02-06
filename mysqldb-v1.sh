#!/bin/bash

#color code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

#check user account is root or not
ID=$(id -u)
if [ $ID -ne 0 ]; then
  echo -e "$RED You should be a root user to execute this script $NOCOLOR"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/mysql.log"

#function to check the status of the command
STAT_CHECK() {
  if [ $1 -eq 0 ]; then
    echo -e "$GREEN Success $NOCOLOR"
  else
    echo -e "$RED Failure $NOCOLOR"
    exit 1
  fi
}

#check DNF Install of mysql server

if dnf list installed mysql-server &>>$LOG_FILE; then
  echo -e "$YELLOW MySQL Server is already installed $NOCOLOR" | tee -a $LOG_FILE
else
  dnf install mysql-server -y &>>$LOG_FILE
  STAT_CHECK $? "Installing MySQL Server"
fi

#Enable and Start mysql service
systemctl enable mysqld &>>$LOG_FILE
STAT_CHECK $? "Enabling MySQL Service"

systemctl start mysqld &>>$LOG_FILE
STAT_CHECK $? "Starting MySQL Service"

#set the user and password for mysql
mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
STAT_CHECK $? "Setting MySQL Root Password"