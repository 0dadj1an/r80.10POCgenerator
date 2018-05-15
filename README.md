# r80.10POCgenerator
scripts related to POC:

poc_first_time_generator_all.sh 

reboot.sh




These scripts can help you to configure Check Point R80.10 all in one POC server

It has been tested on Gaia OS only.



1. Copy both scripts to gateway and chmod +x on them

2. Script reboot.sh is help script to reboot server when first time wizard finish. Run it in sepparate ssh session in backgroud first:
./reboot.sh &

3. in second ssh session run ./poc_first_time_generator_all.sh and follw instruction



scripts will generate following log and lock files:


cmd.txt - tenplate for OS config  
done_lock.lock - done lock notifying that first time and settings were finished successfully
reboot_lock.lock - reboot lock notifying that first time was finished successfully
first_timelog.log - main log file
id.txt - session id for API
mgmt.txt - name of mgmt interface 
mgmtip.txt - ip of mgmt interface
mgmtmask.txt - mask of mgmt interface
monitor.txt - name of monitor interface
os.log - OS log




