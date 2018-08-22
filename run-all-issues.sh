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
echo -e "[DEBUG] Please modify the variable ISSUE_LAST by running './gh-issue-import-ng.py --all' command."
# You can get the "399 new issues" message.
declare -i ISSUE_START
declare -i ISSUE_LAST
ISSUE_START=1
ISSUE_LAST=154

# We have to wait for 3 minutes on average whenever 30 issues are proceeded to avoid service denial.
# If you do not use appriate items and wait time, you will meet " There was a problem during authentication." message.
# We have set a heuristic values from our experience to do not meet unexpected situation such as service error.
# We recommend that you try to set ISSUE_ITEMS among 20(recommended), 30, 40, 50, and 60.
ISSUE_ITEMS=20
ISSUE_WAIT_TIME=$((60*15))

# ----------------------------- Do not modify the below statements ----------------------
echo -e "Error Report:" > ./output.log
for ((i=$ISSUE_START; i<=$ISSUE_LAST;i++)); do
    echo -e "################ Transferring issue '$i' #########################"
    # If you do not append --ignore-milestone --ignore-labels, you will meet "DETAILS: Validation Failed" message.
    yes Y | ./gh-issues-import-ng.py -i $i --ignore-milestone --ignore-labels --ignore-pull-requests
    if [[ $? == 0 ]]; then
        echo -e "Successfully transferred issue $i."
    else
        echo -e "Oooops. Issue $i is failed."
        echo -e "Oooops. Issue $i is failed." >> ./output.log
    fi

    # In case that an issue number is $ISSUE_ITEMS, ...
    if [[ $(($i % $ISSUE_ITEMS)) == 0 ]]; then
        echo -e "Freezing this task for $ISSUE_WAIT_TIME seconds to avoid service denial..."
        sleep $ISSUE_WAIT_TIME
    # In case that an issue number is $ISSUE_ITEMS*3, ...
    elif [[ $(($i % $ISSUE_ITEMS*3)) == 0 ]]; then
        echo -e "Freezing this task for $(($ISSUE_WAIT_TIME*2)) seconds to avoid service denial..."
        sleep $(($ISSUE_WAIT_TIME*2))
    else
        echo -e "Waiting for 1 seconds..."
        sleep 1
    fi
done

