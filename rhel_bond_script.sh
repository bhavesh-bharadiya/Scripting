#!/bin/sh
#script designed for RHEL OS
echo script execution started

#check whether slave interfaces provided or not, limit of max 4 slave interfaces
if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]; then
	echo wrong number of arguments, please provide slave interfaces
exit
fi

#print slave interfaces
echo $1 
echo $2 
echo $3
echo $4

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

#configure bond interface with given bonding mode
nmcli con add type bond con-name bond0 ifname bond0 mode $BOND_MODE

#configure one slave interface if only one slave interface provided in arguments
if [ "$#" -eq 1 ]; then
	nmcli con add type bond-slave con-name bond-slave-$1 ifname $1 master bond0
	nmcli con up bond-slave-$1

#configure two slave interfaces if two slave interfaces provided in arguments
elif [ "$#" -eq 2 ];then
	nmcli con add type bond-slave con-name bond-slave-$1 ifname $1 master bond0
	nmcli con add type bond-slave con-name bond-slave-$2 ifname $2 master bond0
	nmcli con up bond-slave-$1
	nmcli con up bond-slave-$2

#configure three slave interfaces if three slave interfaces provided in arguments
elif [ "$#" -eq 3 ];then
	nmcli con add type bond-slave con-name bond-slave-$1 ifname $1 master bond0
	nmcli con add type bond-slave con-name bond-slave-$2 ifname $2 master bond0
	nmcli con add type bond-slave con-name bond-slave-$3 ifname $3 master bond0
	nmcli con up bond-slave-$1
	nmcli con up bond-slave-$2
	nmcli con up bond-slave-$3

#otherwise configure four slave interfaces
else
	nmcli con add type bond-slave con-name bond-slave-$1 ifname $1 master bond0
	nmcli con add type bond-slave con-name bond-slave-$2 ifname $2 master bond0
	nmcli con add type bond-slave con-name bond-slave-$3 ifname $3 master bond0
	nmcli con add type bond-slave con-name bond-slave-$4 ifname $4 master bond0
	nmcli con up bond-slave-$1
	nmcli con up bond-slave-$2
	nmcli con up bond-slave-$3
	nmcli con up bond-slave-$4
fi

#make bond interface up
nmcli con up bond0
ifup bond0

#interface up, takes time to get ip
sleep 15

#check ping test via bond interface, after ip assigned with the given configuration, take the log also
ping 100.98.4.1 -c 10 >> pinglog_bond_$BOND_MODE

#download RHEL iso via bond interface
wget http://ost.blr.amer.dell.com/pub/redhat/RHEL7/7.3/Server/x86_64/iso/RHEL-7.3-20161019.0-Server-x86_64-boot.iso

#failure case
if [[ $? -ne 0 ]]; then
        echo "wget failed for $BOND_MODE >> pinglog_bond_$BOND_MODE"
fi

#delete bond & bond slave interface configuration because it has to be reconfigured in another bonding mode
nmcli con delete bond0
if [ "$#" -eq 1 ]; then
	nmcli con delete bond-slave-$1
elif [ "$#" -eq 2 ];then
	nmcli con delete bond-slave-$1
	nmcli con delete bond-slave-$2
elif [ "$#" -eq 3 ];then
	nmcli con delete bond-slave-$1
	nmcli con delete bond-slave-$2
	nmcli con delete bond-slave-$3
else
	nmcli con delete bond-slave-$1
	nmcli con delete bond-slave-$2
	nmcli con delete bond-slave-$3
	nmcli con delete bond-slave-$4
fi

#for loop exits here
done
echo script execution completed
