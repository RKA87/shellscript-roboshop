#!/bin/bash

# Color Pattern
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

LOG_DIR="/var/log/shellscript-roboshop"
LOG_FILE="$LOG_DIR/mongodb.log"

#Function to check the validation/status

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOG_FILE
    fi
}

# First Check user account is with root priveliges
USER_ID=$(id -u)
if [ $USER_ID -ne 0 ]; then
    echo -n "you should be a root user account priveligies to run this script"
    exit 1
fi

#Check log directory
if [ ! d $LOG_DIR ]; then
    echo -n "Creating log directory"
    mkdir $LOG_DIR
else
    echo -n "log directory already exists"
fi

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB Repo File"

if dnf list installed | grep mongodb-org; then
    echo -e "$YELLOW MongoDB is already installed on the system $RESET" | tee -a $LOG_FILE
else
    echo -e "$YELLOW MongoDB is not installed on the system we are proceeding with the installation" | tee -a $LOG_FILE
    dnf install mongodb-org -y &>>$LOG_FILE
    VALIDATE $? "Installing MongoDB"
fi

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB Service"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB Service"

systemctl status mongod &>>$LOG_FILE
VALIDATE $? "Checking MongoDB Service Status"

sed -i "s/127.0.0.1/0.0.0.0/" /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections in MongoDB"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB Service"

systemctl status mongod &>>$LOG_FILE
VALIDATE $? "Checking MongoDB Service Status After Restart"