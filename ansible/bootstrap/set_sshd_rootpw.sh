#!/bin/bash -x

MYKEY=$1
ROOTPW=$2
USER=$3
HOST=$4
ssh -i $MYKEY $USER@$HOST "sudo echo $ROOTPW | sudo passwd root --stdin"
ssh -i $MYKEY $USER@$HOST "sudo sed -i 's/PasswordAuthentication/#PasswordAuthentication/g' /etc/ssh/sshd_config"
ssh -i $MYKEY $USER@$HOST "sudo systemctl restart sshd"
sshpass -p $ROOTPW ssh-copy-id root@$HOST
ssh root@$HOST "sed -i 's/ResourceDisk.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf"
ssh root@$HOST "shutdown -r now"
