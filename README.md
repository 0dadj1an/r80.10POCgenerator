

scripts related to POC:

poc_first_time_generator_all.sh

reboot.sh


###################

These scripts can help you to configure Check Point R80.10 all in one POC server (FW+MGMT on single machine)

It has been tested on Gaia OS only and script supposes you have server with at least two interfaces - eth0 for mgmt and eth1 for SPAN port

If you want to have more interfaces, finish scripts and add aditional interfaces in common way


##################

1. Copy both scripts to gateway and chmod +x on them

2. Script reboot.sh is help script to reboot server when first time wizard finish (config_system disconnect session and I dont wont to run it in nohup). Run it in sepparate ssh session in backgroud first --> ./reboot.sh &

3. in second ssh session run ./poc_first_time_generator_all.sh and follw instruction

script will finish first time wizard and set settings - blade activation (FW/AV/ABOT/APP/TE/IPS) + Smart Event and Correlation Unit + IPS update + new POC TP profile with settings according to POC guide


################


scripts will generate following log and lock files:

first_timelog.log - MAIN LOG FILE!

cmd.txt - tenplate for OS config

done_lock.lock - done lock notifying that first time and settings were finished successfully

first_timelog_huge.log  -- detailed log for tshoot

id.txt - session id for API

mgmt.txt - name of mgmt interface

mgmtip.txt - ip of mgmt interface

mgmtmask.txt - mask of mgmt interface

monitor.txt - name of monitor interface

os.log - OS log
