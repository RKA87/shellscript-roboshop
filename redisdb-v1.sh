#!/bin/bash

#Color Code
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NO="\e[0m"

#Check user is root or not
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should be root user to execute this script${NC}"
  exit 1
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/redisdb.log"

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

dnf module disable redis -y | tee -a $LOG_FILE
dnf module enable redis:7 -y | tee -a $LOG_FILE

#Check the redis server is already installed or not
if dnf list installed redis &>>$LOG_FILE; then
    echo -e "${YELLOW}Redis is already installed${NO}" | tee -a $LOG_FILE
else
    dnf install redis -y &>>$LOG_FILE
    STAT_CHECK $? "Installing Redis"
fi

#Update the Bind Address in /etc/redis.conf
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf |tee -a $LOG_FILE
STAT_CHECK $? "Allowing Remote Connections for redisdb"


systemctl enable redis | tee -a $LOG_FILE
STAT_CHECK $? "Enabling Redis Service"

systemctl start redis | tee -a $LOG_FILE
STAT_CHECK $? "Starting Redis Service"

systemctl status redis | tee -a $LOG_FILE
STAT_CHECK $? "Checking Redis Service Status"
