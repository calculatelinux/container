#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

source /var/db/repos/calculate/scripts/ini.sh
source /var/db/repos/container/scripts/functions.sh

action=${1:-}

script_path=$(dirname $(readlink -f $0))
for script in $script_path/step/*.sh; do
	source "$script"
	configure "$action" daemon_name
	daemon_restart+=(${daemon_name:-})
done

for i in ${daemon_restart[@]}; do
	rc-service -s $i stop
done

if [[ ! -e /etc/runlevels/default/homeassistant ]]; then
	cl-setup-system
	rc-update -u
fi
openrc

echo "All is done! Open the link ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]} on your browser."
