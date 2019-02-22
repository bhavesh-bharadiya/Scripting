#!/bin/sh
#script designed for RHEL OS
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
team_file="/etc/sysconfig/network-scripts/ifcfg-team0"

#for debugging
echo $team_file

#remove any team interface configuration file if it is present
rm -rf $team_file

#create team interface configuration file
echo "DEVICE='team0'" >> $team_file
echo "DEVICETYPE='Team'" >> $team_file
echo "ONBOOT='yes'" >> $team_file
echo "BOOTPROTO='dhcp'" >> $team_file

echo "TEAM_CONFIG='{\"runner\": {\"name\": \"$TEAM_MODE\"}, \"link_watch\": {\"name\": \"ethtool\"}}'" >> $team_file

#assign slave interfaces
if [ -z "$1" ]
then
 	echo "no slave interfaces provided"
 	#remove team interface configuration file and exit the script
 	rm -rf $team_file
 	exit
fi

#assign slave interfaces
if [ -z "$2" ]
then
	echo "only one slave interface provided"
fi


#configuration file for slave interface
slave_1_file="/etc/sysconfig/network-scripts/ifcfg-"$1

#for debugging
echo $slave_1_file

#remove any slave interface configuration file if it is present
rm -rf $slave_1_file

#create slave interface configuration file
echo "DEVICE='$1'" >> $slave_1_file
echo "DEVICETYPE='TeamPort'" >> $slave_1_file
echo "ONBOOT='yes'" >> $slave_1_file
echo "TEAM_MASTER='team0'" >> $slave_1_file
echo "TEAM_PORT_CONFIG='{\"prio\": 100}'" >> $slave_1_file


#configuration file for slave interface
slave_2_file="/etc/sysconfig/network-scripts/ifcfg-"$2

#for debugging
echo $slave_2_file

#remove any slave interface configuration file if it is present
rm -rf $slave_2_file

#create slave interface configuration file
echo "DEVICE='$2'" >> $slave_2_file
echo "DEVICETYPE='TeamPort'" >> $slave_2_file
echo "ONBOOT='yes'" >> $slave_2_file
echo "TEAM_MASTER='team0'" >> $slave_2_file
echo "TEAM_PORT_CONFIG='{\"prio\": 100}'" >> $slave_2_file

#make slave interfaces down
ifdown $1
ifdown $2

make slave interfaces up
ifup $1
ifup $2

#make team interface up
ifup team0


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
ifdown team0
sleep 15

#remove team interface configuration file
rm -rf $team_file


#for loop exits here
done 

echo "script execution completed"
