#!/usr/bin/env bash

# @brief: a simple script to import all issue
# This script is to transfer all issues from a repository to another repository
# @note
# Note that github webhook API limits to 030 requests at once with the ?page parameter.
# Note that github webhook API limits to 100 requests at once with the ?per_page parameter.
# https://developer.github.com/v3/#pagination
# @author: Geunsik Lim <leemgs@gmail.com>

# ----------------------------- Do modify the below statements ----------------------
# Please modify the variable ISSUE_LAST by running "./gh-issue-import-ng.py --all" command.
echo -e "\n\n\n"
echo -e "Starting a github issue mover..."
echo -e "[DEBUG] Please modify 'ISSUE_LAST' value by running './gh-issue-import-ng.py --all'."
echo -e "[DEBUG] You can get the ISSUE_LAST value from 'output: xxx new issues' message."
declare -i ISSUE_START
declare -i ISSUE_LAST
ISSUE_START=1
ISSUE_LAST=154

# ----------------------------- Do not modify the below statements ----------------------
# Understanding the rate limit rule of github.com
# First of all, we have to find out the maximum number of requests we are permitted
# by the rate limit rules of github.com by running as following:
# 1. anonymous access: "curl -i https://api.github.com/users/<user_id> | grep RateLimit"
# 2. token key access: "curl -i https://api.github.com/users -u <user_id>:<token_key> | grep RateLimit"
#
# If you don't know an appriate items and a wait time, you will meet the below error message.
# "There was a problem during authentication." message.
# So, we have set a heuristic value from our experience to do not meet unexpected situation
# such as service error. We recommend that you try to set ISSUE_ITEMS among 20(recommended),
# 30, 40, 50, and 60. We have to wait for 20 minutes on average whenever 20 issues are
# proceeded to avoid service denial.
ISSUE_ITEMS=20
ISSUE_WAIT_TIME=$((60*20))
LOG_FILE="output.log"

# If you meet suddenly a "DETAILS: Validation Failed" message, we recommend that you try to
# append "--ignore-milestone --ignore-labels",
IMPORT_OPTION="--ignore-milestone --ignore-labels --ignore-pull-requests"

echo -e "Error Report:" > $LOG_FILE
for ((i=$ISSUE_START; i<=$ISSUE_LAST;i++)); do
    echo -e "################ Transferring issue '$i' #########################"
    yes Y | ./gh-issues-import-ng.py -i $i $IMPORT_OPTION
    if [[ $? == 0 ]]; then
        echo -e "Successfully transferred issue $i."
    else
        # Save error messages into the log file.
        echo -e "Oooops. Issue $i is failed. The message is saved in $LOG_FILE file."
        echo -e "Issue $i is failed." >> $LOG_FILE
        # Let's stop the program.
        exit 1
    fi

    # In case that an issue number is $ISSUE_ITEMS, ...
    if [[ $(($i % $ISSUE_ITEMS)) == 0 ]]; then
        echo -e "Freezing this task for $ISSUE_WAIT_TIME seconds to avoid a service denial..."
        sleep $ISSUE_WAIT_TIME
    else
        echo -e "Waiting for 1 seconds..."
        sleep 1
    fi
done

