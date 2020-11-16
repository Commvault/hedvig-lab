#!/bin/sh

ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./bootstrap.yaml ./tasks/cloud/enable_azure.yaml ./main1a.yaml
ansible-playbook ./main1b.yaml
export JUMP=`grep jump_server ./vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment.internal.cloudapp.net