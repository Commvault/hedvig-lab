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
3. Prepare for Terraform setup by creating a ```./terraform/azure/terraform.tfvars``` file with your subscription id (assumes you've cloned the repo onto your own machine)
```
echo "subscription_id = \"<<your sub-id here>>\"\n" >> ./terraform/azure/terraform.tfvars
```
4. Generate a fresh set of SSH keys, create Azure resources, and capture the resulting jump server IP
```
cd ./ansible
ansible-playbook ./main0.yaml
```
5. Update the local known_hosts, validate connectivity, and prepare the VMs
```
ansible-playbook ./main1.yaml
```
6. Authenticate the vm-deployment server to Azure
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'` && ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment
az login
```
6. Download and extract the software on vm-deployment
```
ansible-playbook ./main2.yaml
```
7. Login to vm-deployment and run the hv_deploy installation
```
export JUMP=`grep jump_server vars.yaml | awk '{split($0,a," "); print a[2]}'`
ssh -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J azureuser@$JUMP azureuser@vm-deployment
su -l admin
/opt/hedvig/bin/hv_deploy --deploy_new_cluster /tmp/hv_deploy.cfg
```
8. Steps to be validated
   1. hv_deploy .... (not sudo) https://documentation.commvault.com/commvault/hedvig/article?p=121158.htm 
   2. https://documentation.commvault.com/commvault/hedvig/article?p=121157.htm
   3. https://documentation.commvault.com/commvault/hedvig/article?p=120084.htm