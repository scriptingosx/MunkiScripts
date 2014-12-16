#!/bin/sh

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

# this will run as a munki install_check script
# exit status of 0 means install needs to run
# exit status not 0 means no installation necessary

ssh_group="com.apple.access_ssh"

# disable ssh
if [[ $(systemsetup -getremotelogin) = 'Remote Login: On' ]]; then
	echo "turning off Remote Login/SSH"
	systemsetup -f -setremotelogin off
fi

# does the group contain the admin group?
admin_uuid=$(dsmemberutil getuuid -G admin)
if [[ $(dscl /Local/Default read Groups/$ssh_group NestedGroups | grep "$admin_uuid" | wc -l) -eq 1 ]]; then
	echo "removing admin group from $ssh_group"
	dseditgroup -o edit -n "/Local/Default" -d admin -t group $ssh_group
fi

exit 0