#!/bin/sh

PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/libexec export PATH

# Script to set the Computer Name

# Armin Briegel

# this script will attempt to set the Computer Name
# first it will attempt to download clients.txt from the munki_repo and look for
# the serialno and computername there
# should that fail the script will look in the nvram, in case it had run successfully before
# should that fail, then it will check wether there is a hostname associated with 
# a built-in Ethernet port (NOT Thunderbolt) and use the first part of the hostname
# (Note: Mac Pros have to be plugged in to Ethernet 1)
# should that still fail it will set a computername of 'ModelName-SerialNo'
# e.g. 'iMac-C02NL7GQFY14'
# then it will set the ComputerName with scutil and store it nvram for the future

# you can add arguments to the script to suppress certain parts for testing
# the arguments are

# ./setComputerName [noserver] [nonvram] [noethernet] [noset]

# the order is important



function ethernetname {
	# is the network active on "Ethernet", or "Ethernet 1", but not "Thunderbolt Ethernet"
	networksetup -listallnetworkservices | while read s; do
		#echo "Service: $s"
		if [[ $s == "Ethernet" ]] || [[ $s == "Ethernet 1" ]]; then
			ipaddr=$(networksetup -getinfo "$s" | awk -F ': ' '/^IP\ address/{print $2}')
			if [[ $ipaddr != "" ]]; then
				hname=$(host "$ipaddr" | awk '{print $NF}' | cut -d '.' -f 1)
			fi
			echo "$hname"
		fi
	done 
}

# Using this method to check the serial number which will also work on the old school Mac Pro
SerialNo=$(/usr/sbin/ioreg -c IOPlatformExpertDevice | awk '/IOPlatformSerialNumber/ {print $4}' | tr -d '"')
#echo $SERIAL

ComputerName=""
Group=""


repo_url=$(defaults read /Library/Preferences/ManagedInstalls SoftwareRepoURL)
if [[ $repo_url == "" ]] ||  [[ $repo_url == "http://munki/repo" ]]; then
	repo_url="http://cal-mini05.usc.edu/munki_repo"
fi

echo "repo url: $repo_url"

# chop off front and back to get server hostname
tmp_url=${repo_url##*://}
munki_host=${tmp_url%%/*}

if [[ $1 != noserver ]]; then
	if [[ $(scutil -r $munki_host) == Reachable* ]]; then
		REC=$(curl --silent --max-time 5 "$repo_url/clients.txt" | grep $SerialNo)
		#echo $REC

		ComputerName=$(echo $REC | cut -d ' ' -f 2 )
		Group=$(echo $REC | cut -d ' ' -f 3 )
		
		echo "found name on server: $ComputerName"
	fi
else
	shift
fi


if [[ $1 != nonvram ]]; then
	if [[ $ComputerName == "" ]]; then
		# try nvram
		ComputerName=$(nvram managed-computer-name 2>/dev/null | cut -f 2)
		Group=$(nvram managed-computer-group 2>/dev/null cut -f 2)
		
		echo "found name in nvram: $ComputerName"
	fi
else
	shift
fi

if [[ $1 != noethernet ]]; then
	if [[ $ComputerName == "" ]]; then
		# try hostname
		ComputerName=$(ethernetname)
		
		echo "found name on Ethernet: $ComputerName"
	fi
else
	shift
fi

if [[ $ComputerName == "" ]]; then
	#we give up, get serial and model name
	modelname=$(system_profiler SPHardwareDataType | awk -F ': ' '/Model\ Name/{print $2}')
	ComputerName="${modelname}-${SerialNo}"
	
	echo "ComputerName: $ComputerName"
fi

if [[ $Group = "" ]]; then
	Group="unknown"
	echo "No group found: using '$Group'"
else
	echo "Group: $Group"
fi

#suppress changes if $1 starts with no
if [[ $1 == noset ]]; then
	echo "$1: supressing actual changes, exiting"
	exit 0
fi

# test id run as root
if [ `whoami` != "root" ]
then
	echo 'Please run this script as root or using sudo'
	exit
fi


# set computername, hostname and local hostname
scutil --set ComputerName $ComputerName
scutil --set HostName $ComputerName
scutil --set LocalHostName $ComputerName

# store computername and group in nvram

nvram managed-computer-name=$ComputerName
nvram managed-computer-group=$Group

# Write the new manifest name for munki
/usr/bin/defaults write /Library/Preferences/ManagedInstalls ClientIdentifier "$Group"

exit 0