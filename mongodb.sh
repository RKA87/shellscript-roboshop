#!/bin/bash

#Variables declaration
USERID=$(id -u)
LOGS_DIR="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_DIR/$0.log" #$0 is the name of the script

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Check root user priveligies

