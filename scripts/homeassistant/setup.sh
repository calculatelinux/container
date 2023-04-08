#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"
scriptpath=$(dirname $(readlink -f $0))

. /var/db/repos/calculate/scripts/ini.sh

chmod o+rw /var/calculate/ini.env
for script in $scriptpath/step/*.sh; do
	"$script"
done
chmod o-rw /var/calculate/ini.env

if [[ ! -e /etc/runlevels/default/homeassistant ]]; then
	cl-setup-system
	rc-update -u
fi
openrc

echo -e "\nAll is done! Open the link ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]} on your browser."
