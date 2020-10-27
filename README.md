# Introduction
Purpose of this document is to outline how to create a Hedvig cluster within a cloud provider. This configuration is designed to provide engineers an education and demonstration environment. These configurations should not be used for production workloads.

The automation scripts following the creation of the cloud resources *may* be useful for creating clusters with on-premises gear. However, this has not been tested as of the time of this writing.

# Prerequisites

This guide assumes the engineer is sufficiently familiar with the use of the following types of resources within the respective cloud provider
- Virtual networks
- Creating virtual machines / instances with block storage
- Firewall settings / security groups
- Resource groups (Azure)
- Storage accounts and containers (Azure)

# Disclaimer
Running cloud resources will incur costs and the engineer should validate the investment required to operate the cluster. "Message and data rates apply".

# General setup

## Overall setup
1. Create a Python virtual environment and install and run Ansible. Remaining Ansible commands will run within the venv environment
``` 
python3 -m virtualenv venv && source venv/bin/activate
pip install ansible
```
2. Creating skeleton parameter files for Terraform and Ansible. Edit the files accordingly
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./bootstrap.yaml
```

## Cloud Provider-specific Notes
### Azure preparation, local software installation, parameter file creation
These are the specific installation instructions for creating the cluster in Azure. Presumes one has a subscription and sufficient privileges to create sufficient CPUs in the environment.

1. Submit a service request to Azure to increase the number of CPUs to 64 for the subscription you will be using.
2. If your local machine is running Windows, it is recommended to install Windows Subsystem for Linux
3. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) on your local machine
4. Add the Azure collection and supporting Python modules into the virtual Python environment
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./tasks/cloud/enable_azure.yaml
```
### Bucket creation to store software
1. Download the Hedvig software from [Commvault](http://cloud.commvault.com) into a local ```/tmp``` directory
2. Create a resource group and bucket to store the Hedvig software zip file. This is separate from the resource group created in subsequent steps as resources in subsequent steps may be created / destroyed with regularity.
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./tasks/cloud/create_swbucket.yaml
```
### Cloud compute, storage, and network resources
1. Generate a fresh set of SSH keys, create Azure resources, and capture the resulting jump server IP
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./main0a.yaml
```
1. Prepare the jump and deployment servers
```
ansible-playbook ./main0b.yaml
export JUMP=`grep jump_server ./vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment.internal.cloudapp.net
az login
exit
ansible-playbook ./main0c.yaml
```
5. Update the local known_hosts, validate connectivity, and prepare the VMs
```
ansible-playbook ./main1.yaml
```
6. Login to vm-deployment
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment.internal.cloudapp.net
```
7. **On vm-deployment**, authenticate to Azure, and run remaining steps on the deployment server (via previously uploaded Ansible script)
```
su -l admin
az login
ansible-playbook /tmp/hedvig/main2.yaml
exit
exit
```
8. Use RDP from your local machine to login to the jump server
9. On the jump server, access the console (via /usr/bin/google-chrome) at http://vm-storagenode0.internal.cloudapp.net. Use ```hotelvictor``` as the username and the password you specified in ```vars.yaml``` as the password

### Resource destruction
Executing the follow step removes all Hedvig software and associated cloud resources. This step is irreversible.   
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./tasks/cloud/destroy_resources.yaml
```
### Software bucket destruction
Executing the follow step removes all Azure resources created with the ```create_swbucket.yaml``` playbook. This step is irreversible.   
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./cloud_resources/destroy_swbucket.yaml
```