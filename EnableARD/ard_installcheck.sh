#!/bin/sh

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

# this will run as a munki install_check script
# exit status of 0 means install needs to run
# exit status not 0 means no installation necessary

# adapted scripts from  here: https://jamfnation.jamfsoftware.com/discussion.html?id=1989

# we need to check wether ARD is running

ardrunning=$(ps ax | grep -c -i "[Aa]rdagent")

if [[ $ardrunning -eq 0 ]]; then
	echo "ARD not running"
	exit 0
fi

# All Users access should be off

all_users=$(/usr/bin/defaults read /Library/Preferences/com.apple.RemoteManagement ARD_AllLocalUsers 2>/dev/null)

if [[ $all_users -eq 1 ]]; then
	echo "All Users Access Enabled"
	exit 0
fi

# and wether the labadmin account is privileged

ard_admins=$(/usr/bin/dscl . list /Users naprivs | cut -d ' ' -f 1)

if [[ $ard_admins != *labadmin* ]]; then
	echo "labadmin no ARD admin"
	exit 0
fi

echo "everything looks great"

exit 1
	
