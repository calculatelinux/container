#!/bin/bash
# README: Install Taiga in Production
# https://docs.taiga.io/setup-production.html#_introduction

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"
scriptpath=$(dirname $(readlink -f $0))

. /var/db/repos/calculate/scripts/ini.sh

echo "Taiga setup"
for script in $scriptpath/step/*.sh; do
	"$script"
done

if [[ ! -e /etc/runlevels/default/taiga ]]; then
	cl-setup-system
	rc-update -u
fi
openrc

echo -e "\nAll is done! Open the link ${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]} on your browser."
