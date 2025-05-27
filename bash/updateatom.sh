#!/usr/bin/env bash

ATOM_VERSION=$(atom --version | awk 'NR==1 {print $3}')

NEWEST_ATOM_RELEASE=$(curl "https://api.github.com/repos/atom/atom/releases/latest")
#NEWEST_ATOM_RELEASE=$(echo "${RELEASES}" | jq '.[0:1][]')
NEWEST_ATOM_VERSION=$(echo "${NEWEST_ATOM_RELEASE}" | jq '.name')
ATOM_DEB_URL=$(echo "${NEWEST_ATOM_RELEASE}" | jq -r '.assets[] | select(.name=="atom-amd64.deb") | .browser_download_url')

if [[ "$NEWEST_ATOM_VERSION" != "$ATOM_VERSION" ]]; then
	echo "Atom versions differ (Local: ${ATOM_VERSION}, Remote: ${NEWEST_ATOM_VERSION})"
	while true; do
		read -p "Would you like to update? " yn
		case "$yn" in
			[Yy]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done

	# download latest deb
	rm -rf /tmp/atom
	mkdir /tmp/atom
	cd /tmp/atom

	# convert deb to PKGBUILD
	curl -Lo atom.deb "${ATOM_DEB_URL}"
	echo -e 'Tabulate\nMIT\nn' | debtap -P atom.deb

	# fix PKGBUILD
	mv atom.deb atom*-bin/
	cd atom*-bin
	sed -i '/^.*_i686/d' PKGBUILD
	sed -i '/^\s*install -D/d' PKGBUILD
	sed -i 's/PUT_FULL_URL_FOR_DOWNLOADING_amd64_DEB_PACKAGE_HERE/atom.deb/' PKGBUILD
	sed -i "s/'kde-runtime'//g" PKGBUILD

	# make package
	makepkg -si

	rm -rf /tmp/atom
fi
