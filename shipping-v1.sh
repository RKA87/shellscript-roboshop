#!/bin/bash

#color codes
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NOCOLOR="\e[0m"

#CHECK ROOT USER ACCESS
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
  echo -e "${RED}You should run this script as root user or with sudo access${NOCOLOR}"
  exit 1
else
  echo -e "${GREEN}You are running the script with root user access${NOCOLOR}"
fi

LOG_DIR="/var/log/shellscript-roboshop"
mkdir -p $LOG_DIR

LOG_FILE="$LOG_DIR/shipping.log"
SCRIPT_DIR=$(pwd)

#Function to print status of the executed command
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
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  STAT_CHECK $? "Adding roboshop user account"
else
  echo -e "${YELLOW}User roboshop already exists${NOCOLOR}" | tee -a $LOG_FILE
fi

#Install Maven for Java application
if dnf list installed maven &>>$LOG_FILE; then
  echo -e "${YELLOW}Maven is already installed${NOCOLOR}" | tee -a $LOG_FILE
else
  dnf install maven -y &>>$LOG_FILE
  STAT_CHECK $? "Installing Maven"
fi

#make application directory and download the application code
mkdir -p /app &>>$LOG_FILE
STAT_CHECK $? "Creating Application Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
STAT_CHECK $? "Downloading Shipping Application Code"

cd /app &>>$LOG_FILE
STAT_CHECK $? "Changing Directory to /app"

rm -rf /app/* &>>$LOG_FILE
STAT_CHECK $? "Removing the existing application directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
STAT_CHECK $? "Extracting Shipping Application Code"

#dependencies to be install
mvn clean package &>>$LOG_FILE
STAT_CHECK $? "Building Shipping Application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
STAT_CHECK $? "Moving Shipping Application Jar"

#Create system service file for shipping application
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
STAT_CHECK $? "Creating Shipping System Service File"

systemctl daemon-reload &>>$LOG_FILE
STAT_CHECK $? "Reloading Systemd Daemon"

systemctl enable shipping &>>$LOG_FILE
STAT_CHECK $? "Enabling Shipping Service"

systemctl start shipping &>>$LOG_FILE
STAT_CHECK $? "Starting Shipping Service"

#need to load the scehma from sqldb
if dnf list installed mysql &>>$LOG_FILE; then
  echo -e "${YELLOW}MySQL client is already installed${NOCOLOR}" | tee -a $LOG_FILE
else
  dnf install mysql -y &>>$LOG_FILE
  STAT_CHECK $? "Installing MySQL Client"
fi

mysql -h mysql.roboshop.internal -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
STAT_CHECK $? "Loading Shipping Schema"

mysql -h mysql.roboshop.internal -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
STAT_CHECK $? "Loading Shipping User data"

mysql -h mysql.roboshop.internal -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
STAT_CHECK $? "Loading Shipping Master Data"

#restart the shippig service
systemctl daemon-reload &>>$LOG_FILE
STAT_CHECK $? "Reloading Shipping Service"

systemctl enable shipping &>>$LOG_FILE
STAT_CHECK $? "Enabling Shipping Service"

systemctl restart shipping &>>$LOG_FILE
STAT_CHECK $? "Restarting Shipping Service"