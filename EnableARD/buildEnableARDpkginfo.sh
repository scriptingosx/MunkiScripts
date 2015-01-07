#!/bin/sh

pkginfo_file="EnableARD.pkginfo"

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/munki export PATH

makepkginfo --name=EnableARD \
	--displayname="Enable Apple Remote Desktop" \
	--pkgvers=1.0 \
	--nopkg \
	--installcheck_script=ard_installcheck.sh \
	--postinstall_script=ard_postinstall.sh \
	--unattended-install > $pkginfo_file

#attempt to read Munki_repo from autopkg
munki_repo=$(defaults read com.github.autopkg MUNKI_REPO)

if [[ -n $munki_repo ]]; then
	if [[ -d $munki_repo ]]; then
		echo "loading to munki repo: $munki_repo"
		mv $pkginfo_file "$munki_repo"/pkgsinfo/config/
	else
		echo "Munki Repo not mounted?"
	fi
fi

exit 0