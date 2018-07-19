#!/bin/bash -f
#
#==============================================================================
#title      :first time generator for POC
#descrition :This script runs first time wizard and configure blades and other
#            settings
#author     :ivo.hrbacek@ixperta.com a laura
#version    :0.0001
#==============================================================================
# CP enviroment variables for cron see sk77300, sk90441
source /opt/CPshrd-R80/tmp/.CPprofile.sh




#variables
SCRIPTFOLDER="$( cd "$(dirname "$0")" ; pwd -P )"
REBOOTLOCK="/etc/.wizard_accepted"
DONELOCK="$SCRIPTFOLDER/done_lock.lock"
LOG="$SCRIPTFOLDER/first_timelog.log"
HUGELOG="$SCRIPTFOLDER/first_timelog_huge.log"
SCRIPTFULLPATH="$SCRIPTFOLDER/poc_first_time_generator_all.sh &"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
TIMESERVER="europe.pool.ntp.org"
LOGOS="$SCRIPTFOLDER/os.log"
CMD="$SCRIPTFOLDER/cmd.txt"
MONITORIF="$SCRIPTFOLDER/monitor.txt"
MGMTIF="$SCRIPTFOLDER/mgmt.txt"
MGMTMASK="$SCRIPTFOLDER/mgmtmask.txt"
MGMTIP="$SCRIPTFOLDER/mgmtip.txt"




#### OS config#####

check_logs(){

    # check LOGOS files and delete them if exists
      if [[ -f "$LOGOS" ]];
                then
                rm -r $LOGOS
                date >> $LOGOS
                printf "script starting...\n" >>$LOGOS
      fi

      if [[ -f "$CMD" ]];
                then
                rm -r $CMD
      fi

     clish -c 'lock database override' -s  >>$LOGOS
     clish -c 'set user admin shell /bin/bash' -s >> $LOGOS
     clish -c 'save config' -s >> $LOGOS
      


}


set_config(){

#set state of interfaces
echo "set interface $mgmt state on" >>$CMD
echo "set interface $monitor state on" >>$CMD
#echo "set interface eth2 state on" >>$CMD

#config interfaces
echo "set interface $monitor monitor-mode on" >>$CMD
echo "set interface $mgmt ipv4-address $ip mask-length $mask " >>$CMD
#echo "set interface eth2 ipv4-address 2.2.2.2 mask-length 24" >>$CMD
echo "set static-route default nexthop gateway address $gw on" >>$CMD
echo "set dns primary $DNS1">>$CMD
echo "set dns secondary $DNS2">>$CMD
echo "set hostname checkpointPOC" >>$CMD
echo "$mgmt" >$MGMTIF
echo "$mask" >$MGMTMASK
echo "$ip" >$MGMTIP
echo "$monitor" >$MONITORIF




}



execute_config(){

clish -c 'lock database override' -s 
clish -f /home/admin/cmd.txt 

sleep 5
printf " Write YES to continue and OS config will be saved and first time wizard will start... [if you changed your mind and config needs to be updated, write any other character..]\n"
read answer

            if [[ "$answer" == "YES" ]];
                then
                    printf "All configured...check os.log if needed\n"
                    printf "execute_config() is okay..\n" >>$LOGOS
                    clish -c 'save config' -s >> $LOGOS
                    break
            else
                 printf "Loading again because it was not commited..\n"
                 printf "again loading parameters from execute_config() method because it was not confirmed..\n" >>$LOGOS
                 printf "removing CMD template from execute_config()\n" >>$LOGOS
                 rm -r $CMD
                 rm -r $MGMTIF
                 rm -r $MGMTMASK
                 rm -r $MGMTIP
                 rm -r $MONITORIF
                 load_parameters
            fi


}



load_parameters(){

        

printf "enter load_parameter method, for more info see os.log..\n" >>$LOG  

    # load parameters and print them as template which will be loaded , if not correct after revision, it will be loaded again
    
    
    # check LOGOS fies
    check_logs

    while true;
    do
            # read data
            echo "enter management interface"
            read mgmt
            echo "enter monitor interface"
            read monitor
            echo "enter management IP"
            read ip
            echo "enter management MASK in format: 24 or 16 or 27 etc."
            read mask
            echo "enter management default gateway"
            read gw
			printf "default host name is checkpointPOC..\n"

			

            # run set method
            set_config

            
            # check rest
            printf "\n"
            printf "Printing config template:\n"
            cat $CMD
            printf "\n"
            printf "Is that correct? Write YES to continue..\n"
            read answer

            if [[ "$answer" == "YES" ]];
                then
                printf "load_parameters() is okay..\n" >> $LOGOS 
                execute_config
                else
                 printf "Loading again..\n" 
                 printf "again loading parameters from load_parameters() method because it was not confirmed..\n" >>$LOGOS
                 printf "removing CMD template from load_parameters()\n" >>$LOGOS
                 rm -r $CMD
                 rm -r $MGMTIF
                 rm -r $MGMTMASK
                 rm -r $MGMTIP
                 rm -r $MONITORIF
                 continue
            fi
    done
    
}


###################   end of OS config  ##########################




########## POC config ################



#set rights for script itself and add to rc.local
set_rights_and_rclocal(){

printf "set rights to script...\n" >>$LOG
printf ""
chown -v admin:bin $SCRIPTFULLPATH  >>$LOG
chmod -v u=rwx,g=rwx,a=rwx $SCRIPTFULLPATH >>$LOG

# returns 0 if text is find in file - in our case searching for path to sript to avoid situation it will be added twice
if grep -Fxq "$SCRIPTFULLPATH" /etc/rc.local
   then
    # path string find in rc.local..
    printf "path to script already in /etc/rc.local..\n" >>$LOG
    

   else
    # not found, add it..
    echo $SCRIPTFULLPATH >> /etc/rc.local
    printf "See rc.local, script path added..\n" >> $LOG
    
    
fi

}



# check api status
check_api(){

	count=0
   
	printf "check api status\n" >>$LOG
	while true;
	do
	sleep 60
	mgmt_cli login -r true > /home/admin/id.txt 
	a=$?
	count = count+1

	if [[ "$a" -eq 1 ]];
       then
	       printf "API not loaded...\n">>$LOG
		   if [[ "$count" -eq 15 ]];
               then
			   count=0
			   api restart >>$LOG
		   fi
			    
	    continue
    else
	    printf "API loaded\n">>$LOG 
	    break
    fi
	done

}





# method for first time wizard settings
run_wizard(){

sleep 5
printf "Starting first time wizard..\n">>$LOG 

	
#basic kernel modification, disable antispoofing and other stuff according to POC gide	
echo "fw_local_interface_anti_spoofing=0" >> $FWDIR/modules/fwkern.conf
echo "fw_antispoofing_enabled=0" >> $FWDIR/modules/fwkern.conf
echo "sim_anti_spoofing_enabled=0" >> $FWDIR/modules/fwkern.conf
echo "fw_icmp_redirects=1" >> $FWDIR/modules/fwkern.conf
echo "fw_allow_out_of_state_icmp_error=1" >> $FWDIR/modules/fwkern.conf
echo "psl_tap_enable=1" >> $FWDIR/modules/fwkern.conf
echo "fw_tap_enable=1" >> $FWDIR/modules/fwkern.conf


#run basic first time wizard
/bin/config_system -s 'install_security_managment=true&install_mgmt_primary=true&install_mgmt_secondary=false&install_security_gw=true&mgmt_gui_clients_radio=any&mgmt_admin_name=admin&mgmt_admin_passwd=checkpoint123&hostname=checkpointPOC&ntp_primary=europe.pool.ntp.org&primary=8.8.8.8&download_info=true&timezone=Europe/Vienna'
echo "first time wizard done - reboot system if you do not have reboot.sh script running ..\n">>$LOG 

}





# set blades and layer settings
set_gateway(){

printf "setting gateway and blades...\n" >>$LOG && printf "setting gateway and blades...\n" >>$HUGELOG
mgmt_cli set simple-gateway name "checkpointPOC" firewall true application-control true url-filtering true ips true anti-bot true anti-virus true threat-emulation true content-awareness true --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "setting gateway issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "setting gateway OK \n" >>$LOG;fi
mgmt_cli set access-layer name "Network" applications-and-url-filtering true data-awareness true detect-using-x-forward-for true --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "setting layer issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "setting layer OK \n" >>$LOG;fi

}



# set rules 
set_rules() {

printf "setting rules...\n" >>$LOG && printf "setting rules...\n" >>$HUGELOG  
mgmt_cli add access-rule layer "Network" position 1 name "Rule 1" action "Accept" track-settings.type "Extended Log" track-settings.accounting "True" track-settings.per-connection "True" track-settings.per-session "True"  --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "rules issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "setting rules OK \n" >>$LOG;fi
mgmt_cli set access-rule name "Cleanup rule" layer "Network" enabled "False"  --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "rules issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "setting rules OK \n" >>$LOG;fi

}



#set TP settings
set_tp_profile(){

printf "TP policy and rules..\n" >>$LOG && printf "setting rules...\n" >>$HUGELOG  
mgmt_cli add threat-profile name "POC" active-protections-performance-impact "High" active-protections-severity "Low or above" confidence-level-high "Detect" confidence-level-low "Detect" confidence-level-medium "Detect" threat-emulation true anti-virus true anti-bot true ips true ips-settings.newly-updated-protections "active" --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG;  if [[ "$?" -eq 1 ]]; then printf "POC profile issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "POC profile OK \n" >>$LOG;fi
mgmt_cli set threat-rule rule-number 1 layer "Standard Threat Prevention" comments "commnet for the first rule" protected-scope "Any" action "POC" install-on "Policy Targets" --format json -s /home/admin/id.txt >>$HUGELOG;  if [[ "$?" -eq 1 ]]; then printf "POC profile rule issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "POC profile rule OK \n" >>$LOG;fi


}



set_tp_settings(){

printf "Get UID of POC TP profile and adding aditional settings..\n" >>$LOG && printf "Get UID of POC TP profile and adding aditional settings..\n" >>$HUGELOG
d=$(mgmt_cli -r true show threat-profile name POC | grep "uid" | head -1  | awk -F':' '{ gsub(" ", "", $0 ); print $2 }')
mgmt_cli -r true set generic-object uid $d teSettings.inspectIncomingFilesInterfaces "ALL" >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "TE isnpect interfaces issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "TE isnpect interfaces OK \n" >>$LOG;fi
mgmt_cli -r true set generic-object uid $d avSettings.inspectIncomingFilesInterfaces "ALL" >>$HUGELOG;  if [[ "$?" -eq 1 ]]; then printf "AV isnpect interfaces issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "AV isnpect interfaces OK \n" >>$LOG;fi
mgmt_cli -r true set generic-object uid $d teSettings.fileTypeProcess "ALL_SUPPORTED" >>$HUGELOG;  if [[ "$?" -eq 1 ]]; then printf "TE all file types issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "TE all file types OK \n" >>$LOG;fi
mgmt_cli -r true set generic-object uid $d avSettings.fileTypeProcess "ALL_FILE_TYPES" >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "AV all file types issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "AV all file types OK \n" >>$LOG;fi

}




# run IPS update
ips_update(){
printf "IPS update..\n" >>$LOG && printf "IPS update..\n" >>$HUGELOG
mgmt_cli run-ips-update -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "IPS update issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "IPS update OK \n" >>$LOG;fi

}




#set monitoring and indexing
set_monitoring_blade_and_indexing(){
printf "Monitor blade settings..\n" >>$LOG && printf "Monitor blade settings..\n" >>$HUGELOG
a=$(mgmt_cli -r true show simple-gateway name checkpointPOC | grep "uid" | head -1  | awk -F':' '{ gsub(" ", "", $0 ); print $2 }') 
#mgmt_cli set generic-object uid $(mgmt_cli -r true show simple-gateway name checkpointPOC | grep "uid" | head -1  | awk -F':' '{ gsub(" ", "", $0 ); print $2 }') enableRtmTrafficReportPerConnection true --format json ignore-warnings true -s /home/admin/id.txt >>$LOG 2>>$LOG
# monitoring blade
#enable monitoring blade 
mgmt_cli set generic-object uid $a realTimeMonitor true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "monitor blade issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Monitor blade OK \n" >>$LOG;fi
# enable parameters
mgmt_cli set generic-object uid $a enableRtmTrafficReportPerConnection true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "monitor blade issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Monitor blade settings01 OK \n" >>$LOG;fi
mgmt_cli set generic-object uid $a enableRtmTrafficReport true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "monitor blade issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Monitor blade settings02 OK \n" >>$LOG;fi
mgmt_cli set generic-object uid $a enableRtmCountersReport true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "monitor blade issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Monitor blade settings03 OK \n" >>$LOG;fi
printf "Indexing and Smart Event settings..\n" >>$LOG && printf "Indexing and Smart Event settings..\n" >>$HUGELOG
#indexing
mgmt_cli set generic-object uid $a logIndexer true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "indexing issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Indexing OK \n" >>$LOG;fi
#correlation unit
mgmt_cli set generic-object uid $a eventAnalyzer true --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "correlation unit issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Correlation Unit OK \n" >>$LOG;fi
#smartevent server
mgmt_cli set generic-object uid $a abacusServer true --format json ignore-warnings true -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "Smart Event issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Smart Event OK \n" >>$LOG;fi

}



# set topology definition
topology_def(){

printf "Topology definition..\n" >>$LOG && printf "Topology definition..\n" >>$HUGELOG
# topology definition 
mgmt_cli set simple-gateway name "checkpointPOC" interfaces.1.name $(cat $MGMTIF) interfaces.1.ipv4-address $(cat $MGMTIP) interfaces.1.ipv4-mask-length $(cat $MGMTMASK) interfaces.1.topology internal interfaces.2.name $(cat $MONITORIF) interfaces.2.ipv4-address 0.0.0.0 interfaces.2.ipv4-mask-length 32 interfaces.2.topology external --format json ignore-warnings true -s /home/admin/id.txt >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "topology definition issue.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Topology definition OK \n" >>$LOG;fi

}




# policy install
policy_install(){

printf "Policy install..\n" >>$LOG
mgmt_cli install-policy policy-package "Standard" access true threat-prevention false targets.1 "checkpointPOC" --format json -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "Access policy install failure.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Access Policy OK \n" >>$LOG;fi
mgmt_cli install-policy policy-package "Standard" access false threat-prevention true targets.1 "checkpointPOC" --format json -s /home/admin/id.txt  >>$HUGELOG; if [[ "$?" -eq 1 ]]; then printf "Threat policy install failure.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "Threat Policy OK \n" >>$LOG;fi

}




# app fail mode
app_failmode(){
  
printf "APP fail mode settings..\n" >>$LOG && printf "APP fail mode settings..\n" >>$HUGELOG
/bin/bash << EOF
psql_client cpm postgres -c "select d1.objid, d2.name from dleobjectderef_data d1, dleobjectderef_data d2 where 
d1.domainid=d2.objid and d1.dlesession=0 and not d1.deleted and d1.name='Application Control & URL Filtering Settings';" > tmp.txt
sed  '/SMC/!d' tmp.txt > tmp2.txt
ObjectName=\`sed '/SMC/!d' tmp.txt | awk -F'[|]' '{print \$(1)}'\`
mgmt_cli -r true set generic-object uid \$ObjectName gwFailure false; if [[ "$?" -eq 1 ]]; then printf "APP fail mode failure.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "App fail mode OK \n" >>$LOG;fi
mgmt_cli -r true set generic-object uid \$ObjectName urlfSslCnEnabled true; if [[ "$?" -eq 1 ]]; then printf "APP SSL categorization mode failure.. check huge log first_timelog_huge.log..\n" >>$LOG; else printf "APP SSL categorization mode OK \n" >>$LOG;fi
rm -r tmp.txt && rm -r tmp2.txt 
EOF

}





# method for fw configuration, calling separate methods..
set_settings(){

printf "Starting configuration of blades..\n">>$LOG && printf "Starting configuration of blades..\n">>$HUGELOG
check_api	#wait till API server will start	
set_gateway #configure gateway and layer

# first publish needs to be done after simple gw settings otherwise it wont work 
printf "Publish..\n" >>$LOG && printf "Publish..\n" >>$HUGELOG # publish changes to continue
mgmt_cli publish  -s /home/admin/id.txt >>$HUGELOG
c=$?

set_rules # set access rules
set_tp_profile # set TP profile and rules

# second publish needs to be done after TPsettings otherwise it wont work 
printf "Publish..\n" >>$LOG && printf "Publish..\n" >>$HUGELOG # publish changes to continue
mgmt_cli publish  -s /home/admin/id.txt >>$HUGELOG
f=$?

set_tp_settings #set TP settings to new POC profile
set_monitoring_blade_and_indexing #set indexing
topology_def # define topology
app_failmode
ips_update

printf "Publish..\n" >>$LOG && printf "Publish..\n" >>$HUGELOG
mgmt_cli publish -s /home/admin/id.txt  >>$HUGELOG 
b=$?


#check status of publish..
if [[ "$c" -eq 1 ]] || [[ "$b" -eq 1 ]] || [[ "$f" -eq 1 ]] ;
 then
	printf "######################################\n"	 >>$LOG 
	printf "firewall settings crashed for some reason, run it again\n"  >>$LOG 
	printf "######################################\n" >>$LOG 
	exit 1
 else
	printf "######################################\n"	 >>$LOG 
	printf "settings success!!!\n" >>$LOG 
	printf "######################################\n" >>$LOG 
	echo "donefile created after first_time wizard, do not delete manually\n" > $DONELOCK
    policy_install
	mgmt_cli logout -s /home/admin/id.txt >>$LOG 2>>$LOG
	sleep 10
	/sbin/shutdown -r now >>$LOG 2>>$LOG
	exit 0
fi

}





main_check(){
  while true;
 # loop checking lock files to make appropriate configs
  do
	

        #neexistuje FIRSTIMELOCK a neexistuje REBOOTLOCK a neexistuje DONELOCK
        if [[ ! -f "$REBOOTLOCK" ]] && [[ ! -f "$DONELOCK" ]];
                then
				# call OS config
                load_parameters
				# set rights for script
				set_rights_and_rclocal
				# run firt time wizard
                run_wizard
        fi

        #existuje REBOOTLOCK a zaroven neexistuje FIRSTTIME
        if [[ -f "$REBOOTLOCK" ]] && [[ ! -f "$DONELOCK" ]] ;
                then
                set_settings
        fi

        #existuje done lock tak se vypni uplne
        if [[ -f "$DONELOCK" ]];
                then
        printf "first time wizard and settings done, not needed to run\n" >>$LOG 
        printf "first time wizard and settings done, not needed to run\n"
                exit 0
        fi

       

  done
}


###################   end of POC config  ##########################


#MAIN CODE BLOCK - just run main check

main_check
