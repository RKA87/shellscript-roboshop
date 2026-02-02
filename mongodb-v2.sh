#!/bin/bash

#Color Coding
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

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

LOG_FILE="$LOG_DIR/mongodb.log"

#Status Check Function to validate the installation status
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $RED FAILED $RESET" | tee -a $LOG_FILE #tee command is nothing but to display output on screen and adding into log file
        exit 1
    else
        echo -e "$2 ... $GREEN SUCCESS $RESET" | tee -a $LOG_FILE
    fi

}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB Repo File"

# First Check Mongodb is already installed or not

if dnf list installed | grep mongodb-org; then
        echo -e "$YELLOW MongoDB is already installed on the system $RESET" | tee -a $LOG_FILE
        exit 0        
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

#sed - stream line editor its like a vi editor command
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE
VALIDATE $? "Allowing Remote Connections in MongoDB"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB Service"

systemctl status mongod &>>$LOG_FILE
VALIDATE $? "Checking MongoDB Service Status After Restart"

#Final Checks using netstat and curl health
netstat -lntp | tee -a $LOG_FILE
validate $? "Validating MongoDB Listening Port"

curl "https://localhost:27017" &>>$LOG_FILE
VALIDATE $? "Validating MongoDB Health using curl"