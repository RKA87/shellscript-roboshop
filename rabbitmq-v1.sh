#!/bin/bash

#color code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

#CHECK ROOT_USER
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo privileges${NOCOLOR}"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/rabbitmq.log"
SCRIPT_DIR=$(pwd)

#FUNCTION TO CHECK STATUS
STAT_CHECK() {
  if [ $1 -ne 0 ]; then
    echo -e "${RED}Failed${NOCOLOR}"
    exit 1
  else
    echo -e "${GREEN}Success${NOCOLOR}"
  fi
}

#copy rabbtimq repo file
cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
STAT_CHECK $? "Copying RabbitMQ repo file"

#installing rabbitmq server

if dnf list installed | grep rabbitmq-server &>>$LOG_FILE; then
  echo -e "${YELLOW}RabbitMQ server is already installed${NOCOLOR}"
else
  echo -e "${YELLOW}Installing RabbitMQ server${NOCOLOR}"
  dnf install rabbitmq-server -y &>>$LOG_FILE
  STAT_CHECK $? "Installing RabbitMQ server"
fi

#Systemctl enable rabbitmq-server
systemctl enable rabbitmq-server &>>$LOG_FILE
STAT_CHECK $? "Enabling RabbitMQ server"    

systemctl start rabbitmq-server &>>$LOG_FILE
STAT_CHECK $? "Starting RabbitMQ server"

#Assign username and password for Rabbitmq server
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
STAT_CHECK $? "Adding RabbitMQ user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
STAT_CHECK $? "Setting permissions for RabbitMQ user"

systemctl restart rabbitmq-server &>>$LOG_FILE
STAT_CHECK $? "Restarting RabbitMQ server"