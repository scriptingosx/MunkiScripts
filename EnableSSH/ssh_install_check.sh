#!/bin/sh

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

# this will run as a munki install_check script
# exit status of 0 means install needs to run
# exit status not 0 means no installation necessary

ssh_group="com.apple.access_ssh"

# Is SSH enabled
if [[ $(systemsetup -getremotelogin) = 'Remote Login: Off' ]]; then
	echo "Remote login is off!"
	exit 0
fi

# Does a group named "com.apple.access_ssh" exist?
if [[ $(dscl /Local/Default list /Groups | grep "${ssh_group}-disabled" | wc -l) -eq 1 ]]; then
	echo "access set to 'All Users'"
	exit 0
elif [[ $(dscl /Local/Default list /Groups | grep "$ssh_group" | wc -l) -eq 0 ]]; then
	echo "no group '$ssh_group'"
	exit 0
fi

# does the group contain the admin group?
admin_uuid=$(dsmemberutil getuuid -G admin)
if [[ $(dscl /Local/Default read Groups/com.apple.access_ssh NestedGroups | grep "$admin_uuid" | wc -l) -eq 0 ]]; then
	echo "admin group not nested in $ssh_group!"
	exit 0
fi

echo "everything seems as it should be, no install needed"
exit 1