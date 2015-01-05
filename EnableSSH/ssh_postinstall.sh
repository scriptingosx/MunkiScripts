#!/bin/sh

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

# this will run as a munki install_check script
# exit status of 0 means install needs to run
# exit status not 0 means no installation necessary

ssh_group="com.apple.access_ssh"

# enable ssh
if [[ $(systemsetup -getremotelogin) = 'Remote Login: Off' ]]; then
	echo "turning on Remote Login/SSH"
	systemsetup -setremotelogin On
fi

# Does a group named "com.apple.access_ssh" exist?
if [[ $(dscl /Local/Default list /Groups | grep "${ssh_group}-disabled" | wc -l) -eq 1 ]]; then
	#rename this group
	echo "renaming group '${ssh_group}-disabled'"
	dscl localhost change /Local/Default/Groups/${ssh_group}-disabled RecordName ${ssh_group}-disabled $ssh_group
elif [[ $(dscl /Local/Default list /Groups | grep "$ssh_group" | wc -l) -eq 0 ]]; then
	# create group
	echo "creating group $ssh_group"
    dseditgroup -o create -n "/Local/Default" -i 399 -g "ABCDEFAB-CDEF-ABCD-EFAB-CDEF0000018F" -r "SSH Service ACL" -T group $ssh_group
fi

# does the group contain the admin group?
admin_uuid=$(dsmemberutil getuuid -G admin)
if [[ $(dscl /Local/Default read Groups/$ssh_group NestedGroups | grep "$admin_uuid" | wc -l) -eq 0 ]]; then
	echo "adding admin group to $ssh_group"
	dseditgroup -o edit -n "/Local/Default" -a admin -t group $ssh_group
fi

exit 0