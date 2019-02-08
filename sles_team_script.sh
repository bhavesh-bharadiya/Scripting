#!/bin/sh
#script designed for SLES OS but checks OS then decides which script to execute
echo script execution started

#check whether slave interfaces provided or not, limit of max 4 slave interfaces
if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
	echo wrong arguments, please provide slave interfaces
	exit
fi

#print slave interfaces
echo $1
echo $2
echo $3
echo $4

#presence of this file indicates RHEL OS is installed in a system
redhat_file="/etc/redhat-release"
if [ -f "$redhat_file" ]
then
        echo "RHEL OS is installed in a system"
        #execute bonding script designed for RHEL OS
        sh /home/rhel_bond_script.sh $1 $2
else
	#otherwise continue this script execution designed for SLES
	echo "SLES OS is installed in a system"

#run the teaming script for all different teaming modes
#for loop starts here
for i in 1 2
do

if [ $i -eq 1 ];then
        TEAM_MODE="loadbalance"
elif [ $i -eq 2 ];then
        TEAM_MODE="activebackup"
fi


#configuration file for team interface
team_file="/etc/sysconfig/network/ifcfg-team0"

#for debugging
echo $team_file

#remove any team interface configuration file if it is present
rm -rf $team_file

#create team interface configuration file
echo "BOOTPROTO='dhcp'" >> $team_file
echo "STARTMODE='auto'" >> $team_file

#assign slave interfaces
if [ -z "$1" ]
then
 	echo "no slave interfaces provided"
 	#remove team interface configuration file and exit the script
 	rm -rf $team_file
 	exit
else
 	echo "TEAM_PORT_DEVICE_0='$1'" >> $team_file
fi

#assign slave interfaces
if [ -z "$2" ]
then
	echo "only one slave interface provided"
else
	echo "TEAM_PORT_DEVICE_1='$2'" >> $team_file
fi

#configure teaming mode for team interface
echo  "TEAM_RUNNER='$TEAM_MODE'" >> $team_file
echo  "TEAM_LB_TX_HASH='ipv4,ipv6,eth,vlan'" >> $team_file
echo  "TEAM_LB_TX_BALANCER_NAME='basic'" >> $team_file
echo  "TEAM_LB_TX_BALANCER_INTERVAL='100'" >> $team_file


#make team interface up
wicked ifup team0

#interface up takes time for ip address
sleep 15

#check ping test via team interface and collect the logs
ping 100.98.4.1 -c 10 >> pinglog_team_$TEAM_MODE

#download RHEL OS iso via team interface
wget http://ost.blr.amer.dell.com/pub/redhat/RHEL7/7.3/Server/x86_64/iso/RHEL-7.3-20161019.0-Server-x86_64-boot.iso

#failure case
if [[ $? -ne 0 ]]; then
        echo "wget failed for $TEAM_MODE >> pinglog_team_$TEAM_MODE"
fi

#make team interface down
wicked ifdown team0
sleep 15

#remove team interface configuration file
rm -rf $team_file


#for loop exits here
done 

echo script execution completed
fi
