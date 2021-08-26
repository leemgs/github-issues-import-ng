#!/usr/bin/env bash

# @brief: a simple script to import all issue
# This script is to transfer all issues from a repository to another repository
# @note
# Note that the GitHub Webhook API limits to 030 requests at once with the ?page parameter.
# Note that the GitHub Webhook API limits to 100 requests at once with the ?per_page parameter.
# https://developer.github.com/v3/#pagination
# @author: Geunsik Lim <leemgs@gmail.com>

# ----------------------------- Do modify the below statements ----------------------
# Write your account name of github.com website
github_com_id="leemgs"

# Declare the number of issues that you want to maintain as a group to avoid a service denial
# when Webhook API requests exceed a max number of a rate limit in github.com.
# Note: If you meet "ERROR: There was a problem during authentication", we recommend
# that you try to define smaller numbers instead of 20 (binding issues as a group).
# For example, 20(default), 10, 8, 6, 4, and 2 issues.
# When the number of specified issues are proceeded, the program sleep for a specified time
# before starting processing a next issue group.
ISSUE_ITEMS_GROUP=2

# ----------------------------- Do not modify the below statements ----------------------
if [[ $1 == "--query" ]]; then
    ./gh-issues-import-ng.py --all
    exit 1
elif [[ $1 == "" || $2 == "" ]]; then
    echo -e "[DEBUG] Please run $0 correctly after reading the below usage."
    echo -e "[DEBUG] If you want to know the last number of issues, visit source repository"
    echo -e "[DEBUG] Usage: $0 [issue_start_no] [ issue_last_no]"
    echo -e "[DEBUG] Usage: $0 --query"
    exit 1
else
    echo -e ""
fi
ISSUE_START=$1
ISSUE_LAST=$2

#Color setting
NC='\033[0m'       # Text Reset
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Display initial messages
echo -e "\n\n\n"
echo -e "${Red}Starting a GitHub issue mover...${NC}"
echo -e "[DEBUG] Please modify 'ISSUE_LAST' value by running './gh-issue-import-ng.py --all'."
echo -e "[DEBUG] You can get the 'ISSUE_LAST' value from 'output: xxx new issues' message."

# Understanding the rate limit rule of github.com
# First of all, we have to find out the maximum number of requests we are permitted
# by the rate limit rules of github.com by running as following:
# 1. The anonymous access: "curl -i https://api.github.com/users/<user_id> | grep RateLimit"
# 2. The token key access: "curl -i https://api.github.com/users -u <user_id>:<token_key> | grep RateLimit"


# Declare wait time that you want to sleep in case of a service denial from github.com.
# We have to wait for 5 minutes by default on average whenever 20 issues are proceeded.
# Note: If you meet "ERROR: There was a problem during authentication", we recommend
# that you try to define a larger number instead of 5 (minutes) to avoid this issue.
# For example, 5 (default), 30, 60, 120, 180, 240, and 300 minutes.
USER_DEFINED_WAIT_TIME=5

# The variable WAIT_TIME_LEVEL has two levels.
# By default, 0 is static time. 1 is dynamic time.
WAIT_TIME_LEVEL=0


LOG_FILE="output.log"

# If you meet suddenly a "DETAILS: Validation Failed" message, we recommend that you try to
# append "--ignore-milestone --ignore-labels",
# IMPORT_OPTION="--ignore-milestone --ignore-labels --ignore-pull-requests"
IMPORT_OPTION="--ignore-milestone --ignore-labels"

# in case of that the import operation generates error situation,
# 0 (for newbie) means that the program just stops the program after display a reason of the error.
# 1 (for expert) means that the program try to import issue again after waiting for appropriate time.
IMPORT_ERR_HANDLING_LEVEL=0

echo -e "Error Report:" > $LOG_FILE
for ((i=$ISSUE_START; i<=$ISSUE_LAST;i++)); do
    echo -e "${Green}####################### Transferring issue '$i' #############################${NC}"
    echo -e "[DEBUG] Run 'yes Y | ./gh-issues-import-ng.py -i $i $IMPORT_OPTION'"
    yes Y | ./gh-issues-import-ng.py -i $i $IMPORT_OPTION
    result=$?
    if [[ $result == 0 ]]; then
        echo -e "Successfully transferred issue $i."
    else
        # Save error messages into the log file.
        echo -e "${Red}Oops. Issue $i is failed. The message is saved in $LOG_FILE file.${NC}"
        echo -e "Issue $i is failed." >> $LOG_FILE
        # Save current limit information
        curl -i https://api.github.com/users/$github_com_id | grep RateLimit >> $LOG_FILE
        epoch_limit_reset=`cat ./$LOG_FILE | grep ^X-RateLimit-Reset | cut -d ':' -f 2 | tr -d '[:space:]'`
        echo -e "The rate limit (60 items) will be recharged after ${Blue}`date --date @${epoch_limit_reset}` (${epoch_limit_reset})${NC}."
        # Stop the program in case of that IMPORT_ERR_HANDLING_LEVEL is 0.
        if [[ $IMPORT_ERR_HANDLING_LEVEL == 0 ]]; then
            echo -e "Stopping the program due to the service denial situation of github.com"
            echo -e "${Red}Rerun $0 after modifying the variable ISSUE_START with $i.${NC}"
            echo -e "${Red}For example,  $0 $i $2 ${NC}"
            exit 1
        # Retry an import operation in case that IMPORT_ERR_HANDLING_LEVEL is 1.
        elif [[ $IMPORT_ERR_HANDLING_LEVEL == 1 ]]; then
            while true; do
                epoch_current_time=`date +%s`
                if [[ $epoch_current_time -gt $epoch_limit_reset ]]; then
                    echo -e "[DEBUG] Retry 'yes Y | ./gh-issues-import-ng.py -i $i $IMPORT_OPTION'"
                    yes Y | ./gh-issues-import-ng.py -i $i $IMPORT_OPTION
                    result_retry=$?
                    if [[ $result_retry == 0 ]]; then
                        echo -e "${Red}Rerunning is okay. Successfully transferred issue $i.${NC}"
                        break
                    else
                        echo -e "Retrial is failed. Stopping the program..."
                        echo -e "${Red}Rerun $0 after modifying the variable ISSUE_START with $i.${NC}"
                        echo -e "${Red}For example,  $0 $i $2 ${NC}"
                        exit 1
                    fi
                else
                    echo -e "[$epoch_current_time] Sleeping for 1 minutes to keep limit rules of github..."
                    sleep 60
                fi
            done
        # TODO: if 2nd tryial is still failed,
        # we need to increate a sleep time more (e.g., 2, 3, 4, and 5 hours).
        else
            echo -e "${Red}The variable IMPORT_ERR_HANDLING_LEVEL is unknown value.${NC}"
        fi
    fi

    # If an issue number is equal to $ISSUE_ITEMS_GROUP, sleep for a specified time.
    if [[ $(($i % $ISSUE_ITEMS_GROUP)) == 0 ]]; then

        if [[ $WAIT_TIME_LEVEL == 0 ]]; then
            # Wait for static time
            ISSUE_WAIT_TIME=$((60*$USER_DEFINED_WAIT_TIME))
            echo -e "Freezing the task for $ISSUE_WAIT_TIME seconds (static time)..."
            sleep $ISSUE_WAIT_TIME
        elif [[ $WAIT_TIME_LEVEL == 1 ]]; then
            # Wait for dynamic time after randomizing a waiting time between 5 and 9 minutes
            while true; do
                data=$((${RANDOM}%($USER_DEFINED_WAIT_TIME*2)))
                if [[ $data -ge $USER_DEFINED_WAIT_TIME ]]; then
                    echo -e "[DEBUG] randomized time (minutes) is $data."
                    break
                fi
            done
            ISSUE_WAIT_TIME=$((60*$data))
            echo -e "Freezing the task for $ISSUE_WAIT_TIME seconds (dynamic time)..."
            sleep $ISSUE_WAIT_TIME
        else
            echo -e "${Red}The variable WAIT_TIME_LEVEL is unknown value.${NC}"
        fi
    else
        echo -e "Waiting for 1 seconds..."
        sleep 1
    fi
done

