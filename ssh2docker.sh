#!/bin/bash
BOXINFO=$(vagrant global-status | grep dockerbox)
STATUS=$(echo $BOXINFO | awk '{print $4}')
ID=$(echo $BOXINFO | awk '{print $1}')

if [[ ! $STATUS -eq "running" ]]; then
    echo "dockerbox not running. Starting"
    vagrant up $ID
fi
vagrant ssh $ID
