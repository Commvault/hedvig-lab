# Introduction
Purpose of this document is to outline how to create a Hedvig cluster within a cloud provider. This configuration is designed to provide engineers an education and demonstration environment. These configurations should not be used for production workloads.

# Prerequisites

This guide assumes the engineer is sufficiently familiar with the use of the following types of resources within the respective cloud provider
- Virtual networks
- Creating virtual machines / instances with block storage
- Firewall settings / security groups
- Resource groups (Azure)
- Storage accounts and containers (Azure)

# Disclaimer
Running cloud resources will incur costs and the engineer should validate the investment required to operate the cluster. "Message and data rates apply".

# Cloud Provider-specific Notes

## Azure
These are the specific installation instructions for creating the cluster in Azure. Presumes one has a subscription and sufficient privileges to create sufficient CPUs in the environment.

### Infrastructure setup
1. Submit a service request to Azure to increase the number of CPUs to 64 for the subscription you will be using.
2. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on your local machine
3. Validate Terraform setup creating a ```./terraform/terraform.tfvars``` file with your subscription id (assumes you've cloned the repo onto your own machine)
```
echo subscription_id = "<<your sub-id here>>\n" >> ./terraform/terraform.tfvars
cd ./ansible
ansible-playbook ./resources_create.yaml
```
1. Get the public IP of the jump / jump_server server created in the previous step and add to ``./ansbile/vars.yaml`` *(automation opportunity)*. The file should look like this when complete:
```
jump_server: <<ip address>
pwd: hedvig
```
1. Configure the keys to permit ssh login for subsequent steps
```
ansible-playbook ./known_hosts.yaml
```
1. Optional step: validate connectivity
```
ansible-playbook ./validate.yaml
```
1. Run the main setup script
```
ansible-playbook ./setup.yaml
```
1. Authenticate the vm-deployment server to Azure
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'`
ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment
az login
```
1. Copy Hedvig software from the bucket to vm-deployment
```
ansible-playbook ./copy_software.yaml
```
1. Copy the bootstrap scripts (entire directory) to vm-jump and then vm-deployment:/tmp/.
   1. Once done, edit ```prep_azenv.sh``` and comment out all lines after prep_deploy in the bottom and run that file.  It will remove the /mnt/resource in that deploy node.
1. While logged into the deployment server, copy software to deployment server and run the .bin files; in this case we copy from an existing blob
1. Login to vm-deployment and run the installation. *this needs to be automated; why does one need to be admin then sudo*
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'`
ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment
su -l admin
export HV_ROOTPASS=hedvig 
export HV_MEM_PROFILE=small_demo
# tools.bin???
sudo /tmp/hedvig_extract.bin && sudo /tmp/rpm_extract.bin
```
1. hv_deploy .... (not sudo) https://documentation.commvault.com/commvault/hedvig/article?p=121158.htm 
2. https://documentation.commvault.com/commvault/hedvig/article?p=121157.htm
3. https://documentation.commvault.com/commvault/hedvig/article?p=120084.htm