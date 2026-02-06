#!/bin/bash

#color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

#CHECK ROOT_USER
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo access${NOCOLOR}"
  exit 1
fi

#LOG_DIR and LOG_FILE
LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/dispatch.log"
SCRIPT_DIR=$(pwd)

# Function to log messages
STAT_CHECK() {
  if [ "$1" -ne 0 ]; then
    echo -e "${RED}$2 ... FAILURE${NO}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Refer the log file for more information: $LOG_FILE${NO}"
    exit 1
  else
    echo -e "${GREEN}$2 ... SUCCESS${NO}" | tee -a "$LOG_FILE"
  fi
}

#add user account for application
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  echo -e "${YELLOW}User roboshop already exists${NOCOLOR}" | tee -a $LOG_FILE
else
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  STAT_CHECK $? "Adding roboshop user"
fi

#check the golang is installed or not
if dnf list installed golang &>/dev/null; then
  echo -e "${GREEN}Golang is already installed${NOCOLOR}"
else
  echo -e "${YELLOW}Installing Golang...${NOCOLOR}"
  dnf install golang -y &>>$LOG_FILE
  STAT_CHECK $? "Installing Golang"
fi

#create application directory and download the application code
mkdir -p /app &>>$LOG_FILE
STAT_CHECK $? "Creating Application Directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
STAT_CHECK $? "Downloading Dispatch Application Code"

cd /app &>>$LOG_FILE
STAT_CHECK $? "Changing Directory to /app"

unzip /tmp/dispatch.zip &>>$LOG_FILE
STAT_CHECK $? "Extracting Dispatch Application Code"

cd /app &>>$LOG_FILE
STAT_CHECK $? "Changing Directory to /app"

#Install the dependencies
go mod init dispatch &>>$LOG_FILE
go get &>>$LOG_FILE
go build &>>$LOG_FILE
STAT_CHECK $? "Initializing Go Modules Dependencies and Building the application"

#system service
cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
STAT_CHECK $? "Copying Dispatch Service File"

systemctl daemon-reload &>>$LOG_FILE
STAT_CHECK $? "Reloading Systemd Daemon"

systemctl enable dispatch &>>$LOG_FILE
STAT_CHECK $? "Enabling Dispatch Service"

systemctl start dispatch &>>$LOG_FILE
STAT_CHECK $? "Starting Dispatch Service"