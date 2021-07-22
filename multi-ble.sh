#!/bin/bash

set -e

export ANSIBLE_CONFIG=.ansible.cfg

vms=(login-1)

# delete all, if any, currently existing VMs that we are going to configure from scratch
delete () {
	printf "deleting currently running VMs\n"
	for vm in ${vms[@]}; do
		multipass delete $vm && printf "deleted $vm\n" || continue
	done
}


# purge the list of deleted VMs
purge (){
	printf "\npurging deleted VMs\n"
	multipass purge
}


# start all VMs in a loop and configure a bare minimum with the cloud-init.yaml file
launch () {
	printf "\nstarting and configuring VMs with multipass and cloud-init\n"
	for vm in ${vms[@]}; do
		multipass launch --name $vm --cloud-init cloud-init.yaml 20.04
	done
}


# create a fresh hosts file so you don't need to edit the ip addresses manually
list () {
	printf "\nupdating the hosts file\n"
	multipass list | tail -n +2 | awk '{ print "[", $1, "]", "\n", $3}' | sed -e 'n;$!G' | sed 's| ||g' > hosts
}

# finally run ansible and configure the VMs
ansible () {
	printf "\nrunning ansible\n"
	ansible-playbook -i hosts -u ubuntu main.yml
}

case $1 in

	all)
		delete
		purge
		launch
		list
		ansible
	;;

	purge)
		delete
		purge
	;;

	launch)
		delete
		purge
		launch
		list
	;;

	ansible)
		ansible
	;;

	*)
		echo "Command '$1' not recognized"
		echo "Valid commands"
		echo "all"
		echo "purge"
		echo "launch"
		echo "ansible"
		exit
	;;
esac
