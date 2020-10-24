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

### Azure preparation, local software installation, parameter file creation
1. Submit a service request to Azure to increase the number of CPUs to 64 for the subscription you will be using.
2. If your local machine is running Windows, it is recommended to install Windows Subsystem for Linux
3. Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) on your local machine
4. Prepare for Terraform setup by creating a ```./terraform/azure/swbucket/terraform.tfvars``` file with your subscription id (assumes you've cloned the repo onto your own machine)
```
echo "subscription_id = \"<<your sub-id here>>\"\n" >> ./terraform/azure/swbucket/terraform.tfvars
```
5. Create a Python virtual environment and install run Ansible. Remaining Ansible commands will run within the venv environment
``` 
python3 -m virtualenv venv
source venv/bin/activate
pip install ansible
```
6. Add the Azure collection and supporting Python modules into the virtual Python environment
```
ansible-playbook ./prepare_env.yaml
```
7. Prepare for Ansible by creating a ```./vars.yaml``` file that looks like this replacing "<<name>>" with the name of the blob you will download
```
pwd: hedvig
jump_server:
software_filename: <<name>>
```

### Bucket creation to store software
1. Download the Hedvig software from [Commvault](http://cloud.commvault.com) into a local ```/tmp``` directory
2. Create a resource group and bucket to store the Hedvig software zip file. This is separate from the resource group created in subsequent steps as resources in subsequent steps may be created / destroyed with regularity.
```
ansible-playbook ./cloud_resources/create_swbucket.yaml
```

### Resource setup
1. Prepare for Terraform setup by creating a ```./terraform/azure/resources/terraform.tfvars``` file with your subscription id (assumes you've cloned the repo onto your own machine)
```
echo "subscription_id = \"<<your sub-id here>>\"\n" >> ./terraform/azure/resources/terraform.tfvars
```
2. Generate a fresh set of SSH keys, create Azure resources, and capture the resulting jump server IP
```
ansible-playbook ./main0.yaml
```
3. Update the local known_hosts, validate connectivity, and prepare the VMs
```
ansible-playbook ./main1.yaml
```
4. Login to vm-deployment
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment.internal.cloudapp.net
```
5. **On vm-deployment**, authenticate to Azure, and run remaining steps on the deployment server (via previously uploaded Ansible script)
```
su -l admin
az login
ansible-playbook /tmp/hedvig/main2.yaml
exit
```
6. Back on your localhost, add a window manager, xrdp, and google chrome to enable RDP into the machine. You will access the Hedvig web console from the jump server
```
ansible-playbook ./main3.yaml
```
7. Use RDP to login to the jump server
8. On the jump server, access the console (via /usr/bin/google-chrome) at http://vm-storagenode0.internal.cloudapp.net. Use ```azureuser``` as the username and the password you specified in ```vars.yaml``` as the password

### Resource destruction
Executing the follow step removes all Hedvig software and associated cloud resources. This step is irreversible.   
```
ansible-playbook ./cloud_resources/destroy_resources.yaml
```
### Software bucket destruction
Executing the follow step removes all Azure resources created with the ```create_swbucket.yaml``` playbook. This step is irreversible.   
```
ansible-playbook ./cloud_resources/destroy_swbucket.yaml
```