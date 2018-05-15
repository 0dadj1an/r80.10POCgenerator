#!/bin/bash -f
#
#==============================================================================
#title      :reboot script
#descrition :This script nees to be run before POC script to reboot machine after config system finished// run as follow: ./reboot.sh &
#author     :ivo.hrbacek@ixperta.com a laura
#version    :0.0001
#==============================================================================
# CP enviroment variables for cron see sk77300, sk90441
source /opt/CPshrd-R80/tmp/.CPprofile.sh


#variables
SCRIPTFOLDER="$( cd "$(dirname "$0")" ; pwd -P )"
REBOOTLOCK="$SCRIPTFOLDER/reboot_lock.lock"

while true; do sleep 10; if [[ -f "$REBOOTLOCK" ]]; then shutdown -r now; fi; done 
