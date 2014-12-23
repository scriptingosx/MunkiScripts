#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/libexec export PATH

localName=$(scutil --get ComputerName)

# if we can get a name from nvram and the local name matches, then don't run script
ComputerName=$(nvram managed-computer-name 2>/dev/null | cut -f 2)
if [[ $localName == $ComputerName ]]; then
	# everything is fine
	echo "everything is fine, exiting"
	exit 1
fi

# if we can get a name from the munki server and the local name matches, then don't run script
repo_url=$(defaults read /Library/Preferences/ManagedInstalls SoftwareRepoURL)
if [[ $repo_url == "" ]] ||  [[ $repo_url == "http://munki/repo" ]]; then
	repo_url="http://cal-mini05.usc.edu/munki_repo"
fi

# chop off front and back to get server hostname
tmp_url=${repo_url##*://}
munki_host=${tmp_url%%/*}

# Using this method to check the serial number which will also work on the old school Mac Pro
SerialNo=$(/usr/sbin/ioreg -c IOPlatformExpertDevice | awk '/IOPlatformSerialNumber/ {print $4}' | tr -d '"')

if [[ $(scutil -r $munki_host) == Reachable* ]]; then
	REC=$(curl --silent --max-time 5 "$repo_url/clients.txt" | grep $SerialNo)
	#echo $REC

	ComputerName=$(echo $REC | cut -d ' ' -f 2 )
	
	echo "found name on server: $ComputerName"
	
	if [[ $localName == $ComputerName ]]; then
		# everything is fine, but we will only get here if nvram does not contain the name
		if [[ $(whoami) == 'root' ]]; then
			echo "updating ComputerName in nvram to $ComputerName"
			nvram managed-computer-name=$ComputerName
		fi
		echo "everything is fine, exiting"
		exit 1
	fi
fi


#otherwise run the script
exit 0
