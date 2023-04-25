#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

source /var/db/repos/calculate/scripts/ini.sh
source /var/db/repos/container/scripts/functions.sh

action=${1:-}

log_dir=/var/log/calculate/cl-setup
rm -rf $log_dir
mkdir -p $log_dir

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

	echo 'Launch preparation'
	ebegin 'Final setup'
	cl-setup-system >>$log_dir/setup.log
	rc-update -u >>$log_dir/setup.log
	eend

	ebegin 'Starting services'
	openrc >>$log_dir/setup.log
	eend
else
	openrc
fi

echo "All is done! Open the link ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]} on your browser."
