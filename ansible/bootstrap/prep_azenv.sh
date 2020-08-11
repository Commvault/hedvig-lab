#!/bin/bash -x

mykey=~/.ssh/hedvig
domain=internal.cloudapp.net
deploy=vm-deployment
nodes='vm-storagenode0 vm-storagenode1 vm-storagenode2'
cvms='vm-proxy'
clustername=bluefire

# ssh permissions and root pwd
init_key() {
	mkdir -p tmpdir
	for i in $nodes $deploy $cvms; do
		if ! [ -f tmpdir/$i.key ]; then
			./set_sshd_rootpw.sh $mykey hedvig admin $i
			touch tmpdir/$i.key
		fi
	done
}

prep_deploy() {
	# deploy node prep
	if ! [ -f tmpdir/$deploy.done ]; then
		echo "sleeping for 15 seconds"
		sleep 15
		scp deploy.* root@$deploy:/root
		scp hedvig* root@$deploy:/root
		ssh root@$deploy 'bash /root/deploy.sh'
		touch tmpdir/$deploy.done
	fi
}

# fix names

prep_hostnames() {
	for i in $deploy; do
		myname=$(ssh root@$i hostname)
		if [[ $myname != *"."* ]]; then
			echo "setting name for $i"
			myfqdn=$myname.$domain
			setname=$(ssh root@$i hostnamectl set-hostname $myfqdn)
			myname=$(ssh root@$i hostname)
			echo $myname
			echo "$i  $myname" >etc_hosts
		fi
	done

	for i in $nodes; do
		myname=$(ssh root@$i hostname)
		if [[ $myname != *"."* ]]; then
			echo "setting name for $i"
			myfqdn=$myname.$domain
			setname=$(ssh root@$i hostnamectl set-hostname $myfqdn)
			myname=$(ssh root@$i hostname)
			echo "$i  $myname" >>etc_hosts
		fi
	done

	for i in $cvms; do
		myname=$(ssh root@$i hostname)
		if [[ $myname != *"."* ]]; then
			echo "setting name for $i"
			myfqdn=$myname.$domain
			setname=$(ssh root@$i hostnamectl set-hostname $myfqdn)
			myname=$(ssh root@$i hostname)
			echo "$i  $myname" >>etc_hosts
		fi
	done
}

# Put names back into /etc/hosts
prep_etc_hosts() {
	for i in $deploy $nodes $cvms; do
		if ! [ -f tmpdir/$i.hosts ]; then
			scp etc_hosts* root@$i:/root
			ssh root@$i 'cp /etc/hosts /etc/hosts.bak;cat /root/etc_hosts.orig /root/etc_hosts > /etc/hosts'
			touch tmpdir/$i.hosts
		fi
	done
}

##################################################################

prep_ansible_info() {
	# Setup for ansible
	for i in $deploy; do
		if ! [ -f tmpdir/$clustername.ansi ]; then
			scp azure.map root@$i:/home/admin/
			cp sample.ansi $clustername.ansi
			sed -i "s/sample/$clustername/g" $clustername.ansi
			scp $clustername.ansi root@$i:/home/admin/
			touch tmpdir/$clustername.ansi
		fi
	done

	for i in $nodes; do
		if ! [ -f tmpdir/$i.map ]; then
			ssh root@$i 'mkdir -p /etc/hedvig'
			scp dev.ignore root@$i:/etc/hedvig
			scp ssd.manual root@$i:/etc/hedvig
			touch tmpdir/$i.map
		fi
	done

}

#init_key
# prep_deploy
# maybe not prep_hostnames
# maybe not prep_etc_hosts
#prep_ansible_info
