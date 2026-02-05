#!/bin/bash

#color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NC="\e[0m"

#check root user access
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo privileges${NC}"
  exit 1
fi

#Log Directory
LOG_DIR="/tmp/roboshop/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/cart.log"

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
STAT_CHECK $? "Disable NodeJS module"

if dnf list installed nodejs &>>$LOG_FILE; then
    echo -e "${GREEN}Nodejs is already installed${NC}" | tee -a $LOG_FILE
else
    dnf module enable nodejs:24 -y | tee -a $LOG_FILE
    STAT_CHECK $? "Enable NodeJS module"
    dnf install nodejs -y | tee -a $LOG_FILE
    STAT_CHECK $? "Installing Nodejs"
fi

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop | tee -a $LOG_FILE
    STAT_CHECK $? "Adding roboshop user"
else
    echo -e "${GREEN}roboshop user already exists${NC}" | tee -a $LOG_FILE
fi

#create application directory
mkdir -p /app | tee -a $LOG_FILE
STAT_CHECK $? "Creating application directory"

#download application code
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$LOG_FILE

cd /app | tee -a $LOG_FILE
STAT_CHECK $? "Changing directory to /app"

rm -rf /app/* | tee -a $LOG_FILE
STAT_CHECK $? "Cleaning old application content"

unzip /tmp/cart.zip | tee -a $LOG_FILE
STAT_CHECK $? "Extracting cart application code"

npm install &>>$LOG_FILE
STAT_CHECK $? "Installing Nodejs dependencies"

#configure backend service
cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
STAT_CHECK $? "Copying cart service file"

systemctl daemon-reload | tee -a $LOG_FILE
STAT_CHECK $? "Reloading systemd daemon"

systemctl enable cart | tee -a $LOG_FILE
STAT_CHECK $? "Enabling cart service"

systemctl start cart | tee -a $LOG_FILE
STAT_CHECK $? "Starting cart service"