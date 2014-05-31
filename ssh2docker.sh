#!/bin/bash


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
   if [ -z "$command" ]; then
      ssh -q -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d $(pwd) ]]; then cd $(pwd); fi; bash"
   else
      ssh -q -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d $(pwd) ]]; then cd $(pwd); fi; $command"
   fi
   if [[ ! $? -eq 0 ]]; then
       cachedid_error=1
   fi
fi


#if that didn't work, try to find the ID
if [ -z "$ID" -o $cachedid_error -eq 1 ]; then
   #echo "ID not cached or wrong, try to find out"
   BOXINFO=$(vagrant global-status | grep dockerbox)
   STATUS=$(echo $BOXINFO | awk '{print $4}')
   NEWID=$(echo $BOXINFO | awk '{print $1}')
   if [ "$NEWID" != "$ID" -o ! $STATUS == "running"  ]; then
       ID=$NEWID
       if [[ ! $STATUS == "running" ]]; then
            echo "dockerbox not running. Starting"
            vagrant up $ID
       fi
       PORT=$(vagrant ssh-config $ID | grep Port | awk '{print $2}')
       echo "New dockerbox id, write it and login"
       echo -n "$ID:$PORT" > /tmp/dockerboxid
       if [ -z "$command" ]; then
          ssh -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d $(pwd) ]]; then cd $(pwd); fi; bash"
	   else
          ssh -p $PORT -i  ~/.vagrant.d/insecure_private_key -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -t vagrant@127.0.0.1 "if [[ -d $(pwd) ]]; then cd $(pwd); fi; $command"
       fi
    fi
fi
