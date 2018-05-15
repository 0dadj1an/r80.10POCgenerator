# r80.10POCgenerator
script related to POC:

poc_first_time_generator_all.sh 





This script can help you to configure Check Point R80.10 all in one POC server

It has been tested on Gaia OS only.



1. Copy script to gateway and chmod +x on that


2. run ./poc_first_time_generator_all.sh and follow instructions


script will finish first time wizard and set settings - blade activation (FW/AV/ABOT/APP/TE/IPS) + Smart Event and Correlation Unit + IPS update + new POC TP profile with settings according to POC guide

script will generate following log and lock files:


cmd.txt - tenplate for OS config  

done_lock.lock - done lock notifying that first time and settings were finished successfully

first_timelog.log - main log file

id.txt - session id for API

mgmt.txt - name of mgmt interface 

mgmtip.txt - ip of mgmt interface

mgmtmask.txt - mask of mgmt interface

monitor.txt - name of monitor interface

os.log - OS log




