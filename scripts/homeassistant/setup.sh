#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

source /var/db/repos/calculate/scripts/ini.sh
source /var/db/repos/container/scripts/functions.sh
script_path=$(dirname $(readlink -f $0))

if [[ ! -e /var/calculate/homeassistant ]]; then
	first_start=1
else
	first_start=
fi

log_dir=/var/log/calculate/cl-setup
rm -rf $log_dir
mkdir -p $log_dir

if [[ $first_start && ! -e /dev/ttyUSB0 && ! -e /dev/ttyACM0 ]]; then
	while true; do
		read -p "Zigbee2MQTT device is not found, the configuration will be done without Zigbee to MQTT bridge (y/n)? " answer
		case $answer in
			[Yy]* ) break; exit ;;
			[Nn]* ) exit ;;
			* ) echo "Please answer yes or no." ;;
		esac
	done
fi

# Установка/настройка и проверка обновлений
configurate() {
	local check=${1:-}

	for step in $script_path/step/*.sh; do
		source "$step"
		if [[ $check ]]; then
			configure check result
		else
			configure
		fi
	done

	if [[ $check ]]; then
		return ${result:-}
	fi
}


if [[ $first_start ]]; then
	configurate

	echo 'Launch preparation'
	ebegin 'Final setup'
	cl-setup-system >>$log_dir/setup.log
	rc-update -u >>$log_dir/setup.log
	eend

	ebegin 'Starting services'
	openrc >>$log_dir/setup.log
	eend

	echo "All is done! Open the link ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]} on your browser."
else
	configurate check && {
		echo 'No updates available.'
	} || {
		echo
		while true; do
			read -p "Do you wish to install this update (y/n)? " answer
			case $answer in
				[Yy]* ) configurate; exit ;;
				[Nn]* ) exit ;;
				* ) echo "Please answer yes or no." ;;
			esac
		done
	}
fi
