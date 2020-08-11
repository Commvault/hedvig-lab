import subprocess
import sys
import argparse

# Cleans unused Disks, NIC's, Public IP and Network Security Groups(NSG).
# Check https://azurecitadel.github.io/guides/cli/cli-3-jmespath/ for more Azure CLI query options

def delete_disks(resource_group):

    disklist=[]
    sp = subprocess.Popen('az disk list --resource-group {0} --output tsv --query "[?managedBy == null].name"'.format(resource_group) ,shell=True,stdout=subprocess.PIPE)
    output, _ = sp.communicate()
    print output

    disklist = output.split()

    for i in disklist:
        cmd = "az disk delete --resource-group {0} --yes --name {1}".format(resource_group,i)
	sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
	output, _ = sp.communicate()
	print output

def delete_nics(resource_group):

    niclist = []
    sp = subprocess.Popen('az network nic list --resource-group {0} --output tsv --query "[?virtualMachine == null].name"'.format(resource_group) ,shell=True,stdout=subprocess.PIPE)
    output, _ = sp.communicate()
    print output 

    niclist = output.split()
    for i in niclist:
        cmd = "az network nic delete --resource-group {0} --name {1}".format(resource_group,i)
        sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        output, _ = sp.communicate()
        print output

def delete_public_ip(resource_group):

    piplist = []
    sp = subprocess.Popen('az network public-ip list --resource-group {0} --output tsv --query "[?ipConfiguration == null].name"'.format(resource_group),shell=True,stdout=subprocess.PIPE)
    output, _ = sp.communicate()
    print output

    piplist = output.split()
    for i in piplist:
        cmd = "az network public-ip delete --resource-group {0} --name {1}".format(resource_group,i)
        sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        output, _ = sp.communicate()
        print output

def delete_nsg(resource_group):

    nsglist = []
    sp = subprocess.Popen('az network nsg list --resource-group {0} --output tsv --query "[?networkInterfaces == null].name"'.format(resource_group),shell=True,stdout=subprocess.PIPE)
    output, _ = sp.communicate()
    print output

    nsglist = output.split()
    for i in nsglist:
        cmd = "az network nsg delete --resource-group {0} --name {1}".format(resource_group,i)
        sp = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
        output, _ = sp.communicate()
        print output

parser = argparse.ArgumentParser()
parser.add_argument("-r", "--resource_group", help="Name of Resource Group on Azure", required=True)
parser.add_argument("-u", "--azure_username", help="Login username for Azure", required=True)
parser.add_argument("-p", "--azure_password", help="Login password for Azure", required=True)
args = parser.parse_args()

resource_group = args.resource_group
sp = subprocess.Popen('az login -u {0} -p {1}'.format(args.azure_username, args.azure_password),shell=True,stdout=subprocess.PIPE)
output, _ = sp.communicate()
print output

delete_disks(resource_group)
delete_nics(resource_group)
delete_public_ip(resource_group)
delete_nsg(resource_group)
