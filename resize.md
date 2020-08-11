*This procedure should not be necessary if the VM sizes are D8 or higher*

#### Deployment server OS resizing
The default os disk (/) is not big enough nor was I able to specify a larger one at creation time. So this series of steps is necessary to modify the / disk. 
1. Increase the size of the disk on Azure from any machine with Azure's CLI
```
az vm deallocate -g rg-hedvig -n vm-deployment
az disk update -g rg-hedvig-n vm-deployment-disk-os --size-gb 128
az vm start -g rg-hedvig -n vm-deployment
```
2. Login to vm-deployment and repartition the disk. See https://kalaivairamuthu.wordpress.com/2019/07/06/9-easy-steps-to-increase-your-root-volume-of-azure-instance/ for an interactive explanation of the commands.
```
sudo fdisk /dev/sda <<EOF
d
2
n
p
2


w
EOF
```
1. Reboot the VM ```sudo reboot```
2. Login to the deployment server from the jump server
```
ssh admin@vm-deployment
``` 
3. Resize the partition using ```sudo xfs_growfs /dev/sda2```
