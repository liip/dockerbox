#!/bin/bash

function ssh_to_box() {
   local command=$@
   if [ -z "$command" ]; then
     ssh -q -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d '$(pwd)' ]]; then cd '$(pwd)'; fi; bash"
   else
     ssh -q -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d '$(pwd)' ]]; then cd '$(pwd)'; fi; $command"
   fi

}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

command=""

while getopts "vc:" opt; do
    case "$opt" in
    c)  command=$OPTARG
        ;;
    v)  set -v
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

if [[ -z "$command" ]]; then
 command=$@
fi

cachedid_error=0

if [[ -e "/tmp/dockerboxid" ]]; then
   ID=$(cat /tmp/dockerboxid | cut -f 1 -d ":");
   PORT=$(cat /tmp/dockerboxid | cut -f 2 -d ":");
   if [ ! -z "$ID" -a ! -z "$PORT" ]; then
       ssh_to_box $command
       if [[ ! $? -eq 0 ]]; then
           cachedid_error=1
       fi
   else
       ID=""
       PORT=""
   fi
fi


#if that didn't work, try to find the ID
if [ -z "$ID" -o $cachedid_error -eq 1 ]; then
   #echo "ID not cached or wrong, try to find out"
   BOXINFO=$(vagrant global-status | grep dockerbox)
   if [ -z "$BOXINFO" ]; then
       echo "*******"
       echo "dockerbox not found in 'vagrant global-status'"
       echo "*******"
       echo " Please start it manually with 'vagrant up' in the"
       echo " dockerbox directory"
       exit 2
   fi
   STATUS=$(echo $BOXINFO | awk '{print $4}')
   NEWID=$(echo $BOXINFO | awk '{print $1}')
   if [ "$NEWID" != "$ID" -o ! $STATUS == "running"  ]; then
       ID=$NEWID
       if [[ ! $STATUS == "running" ]]; then
            echo "dockerbox not running. Starting"
            vagrant up $ID
       fi
       PORT=$(vagrant ssh-config $ID | grep Port | awk '{print $2}')
       if [ -z "$PORT" ]; then
            echo "No ssh port found, maybe dockerbox is not running, try starting it"
            vagrant up $ID
            if [[ $? -eq 0 ]]; then
               echo "Vagrant box up, restarting script"
               $0 $command
               exit 0
            else
               echo "ERROR: Something went wrong, try (re)starting the dockerbox by hand"
               echo " with vagrant up"
               exit 1
            fi
       fi
       echo "New dockerbox id, write it and login"
       echo -n "$ID:$PORT" > /tmp/dockerboxid
       ssh_to_box $command
    fi
fi
