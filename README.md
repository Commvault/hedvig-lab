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
## Cloud Provider-specific Notes

### Bucket creation to store software
This step is required only once to faciliate repeated creation / destruction of the Hedvig cluster and associated cloud resources
1. Download the Hedvig software from [Commvault](http://cloud.commvault.com) into a local ```/tmp``` directory
2. Create a resource group and bucket to store the Hedvig software zip file. This is separate from the resource group created in subsequent steps as resources in subsequent steps may be created / destroyed with regularity. It requires steps from ```local.yaml``` to be executed first
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./local.yaml
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./swbucket_create.yaml
```
### Azure preparation, local software installation, parameter file creation
These are the specific installation instructions for creating the cluster in Azure. Presumes one has a subscription and sufficient privileges to create sufficient CPUs in the environment.

1. Submit a service request to Azure to increase the number of CPUs to 64 for the subscription you will be using.
2. If your local machine is running Windows, it is recommended to install Windows Subsystem for Linux
3. Run the following playbooks within the virtual Python environment. Do not attempt to combine setup0 and setup1 as there is a "pause" introduced because of the dynamic nature of the Ansible inventory.
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./setup0.yaml
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./setup1.yaml
ansible-playbook ./setup2.yaml
```
4. Login to vm-deployment
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment.internal.cloudapp.net
```
5. **On vm-deployment**, authenticate to Azure, and run remaining steps on the deployment server (via previously uploaded Ansible script)
```
su -l admin
az login
ansible-playbook /tmp/hedvig/setup3.yaml
exit
exit
```
6. Use RDP from your local machine to login to the jump server
7. On the jump server, access the console (via /usr/bin/google-chrome) at http://vm-storagenode0.internal.cloudapp.net. Use ```hotelvictor``` as the username and the password you specified in ```vars.yaml``` as the password

### Resource destruction
Executing the follow step removes the Hedvig cluster and associated cloud resources. This step is irreversible. There is no backup.
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./destroy.yaml
```
### Software bucket destruction
Executing the follow step removes all Azure resources created with the ```swbucket_create.yaml``` playbook. This step is irreversible.   
```
ANSIBLE_CONFIG=./ansible-local.cfg ansible-playbook ./swbucket_destroy.yaml
```