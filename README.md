# Scripting
Some scripts for Automation

# How to execute
the contents of "/etc/ansible/hosts" file should be in below format: interface1 and interface2 are the arguments given to playbook which are configured
as bonding slave interface. OS ip address is must required for execution and the interface configured for OS ip address should not be a part of bonding
configuration.

[SERVERS]
100.98.6.164 ansible_connection=ssh ansible_ssh_user=root ansible_ssh_pass=dell01 interface1=p6p1 interface2=p6p2


