#!/bin/sh
#script designed for usb sanity testing

echo "script execution started"

#check whether usb drive is mounted or not
output=$(lsblk | grep -i disk | grep -i media)
if [ -z "$output" ]
then
	echo "usb drive not mounted"
else
	echo "usb drive is mounted"
	echo $output
fi

#run IO monkey, starts 10 threads on each partition, 10MB file size for, 16K trasfer size for all I/O, run for two minutes
/home/iomonkey_x64 -t10 -f10 -b32 -i2 -p15

echo "script execution completed"
