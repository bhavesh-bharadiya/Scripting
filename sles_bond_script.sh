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

#run the bonding script for all different bonding modes
#for loop starts here
for i in 1 2 3
do

if [ $i -eq 1 ];then
        BOND_MODE="active-backup"
elif [ $i -eq 2 ];then
        BOND_MODE="balance-tlb"
elif [ $i -eq 3 ];then
        BOND_MODE="balance-alb"
fi


#configuration file for bond interface
bond_file="/etc/sysconfig/network/ifcfg-bond0"

#for debugging
echo $bond_file

#remove any bond interface configuration file if it is present
rm -rf $bond_file

#create bond interface configuration file
echo "BOOTPROTO='dhcp'" >> $bond_file
echo "STARTMODE='onboot'" >> $bond_file
echo "BONDING_MASTER='yes'" >> $bond_file
echo "NAME='bond0'" >> $bond_file

#assign slave interfaces
if [ -z "$1" ]
then
 	echo "no slave interfaces provided"
 	#remove bond interface configuration file and exit the script
 	rm -rf $bond_file
 	exit
else
 	echo "BONDING_SLAVE_0='$1'" >> $bond_file
fi

#assign slave interfaces
if [ -z "$2" ]
then
	echo "only one slave interface provided"
else
	echo "BONDING_SLAVE_1='$2'" >> $bond_file
fi

#configure bonding mode for bond interface
echo  "BONDING_MODULE_OPTS='mode=$BOND_MODE miimon=100'" >> $bond_file

#configuration file for bond slave interface
slave_1_file="/etc/sysconfig/network/ifcfg-"$1

#for debugging
echo $slave_1_file

#remove any bond slave interface configuration file if it is present
rm -rf $slave_1_file

#create bond slave interface configuration file
echo "BOOTPROTO='none'" >> $slave_1_file
echo "ETHTOOL_OPTIONS=''" >> $slave_1_file
echo "STARTMODE='hotplug'" >> $slave_1_file
echo "DHCLIENT_SET_DEFAULT_ROUTE='yes'" >> $slave_1_file
echo "MASTER='bond0'" >> $slave_1_file
echo "SLAVE='yes'" >> $slave_1_file

#configuration file for bond slave interface
slave_2_file="/etc/sysconfig/network/ifcfg-"$2

#for debugging
echo $slave_2_file

#remove any bond slave interface configuration file if it is present
rm -rf $slave_2_file

#create bond slave interface configuration file
echo "BOOTPROTO='none'" >> $slave_2_file
echo "ETHTOOL_OPTIONS=''" >> $slave_2_file
echo "STARTMODE='hotplug'" >> $slave_2_file
echo "DHCLIENT_SET_DEFAULT_ROUTE='yes'" >> $slave_2_file
echo "MASTER='bond0'" >> $slave_2_file
echo "SLAVE='yes'" >> $slave_2_file

#make bond interface up
wicked ifup bond0

#interface up takes time for ip address
sleep 15

#check ping test via bond interface and collect the logs
ping 100.98.4.1 -c 10 >> pinglog_bond_$BOND_MODE

#download RHEL OS iso via bond interface
wget http://ost.blr.amer.dell.com/pub/redhat/RHEL7/7.3/Server/x86_64/iso/RHEL-7.3-20161019.0-Server-x86_64-boot.iso

#failure case
if [[ $? -ne 0 ]]; then
        echo "wget failed for $BOND_MODE >> pinglog_bond_$BOND_MODE"
fi

#make bond interface down
wicked ifdown bond0
sleep 15

#remove bond interface configuration file
rm -rf $bond_file

if [ -f $slave_1_file ]
then
	echo $slave_1_file removing
	#remove bond slave interface configuration file
	rm -rf $slave_1_file
fi

if [ -f $slave_2_file ]
then
	echo $slave_2_file removing
	#remove bond slave interface configuration file
	rm -rf $slave_2_file
fi

#for loop exits here
done 

echo script execution completed
fi
