#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - zigbee2mqtt -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

if [[ ! -e ~/.venv-live ]]; then
	einfo 'Clone Zigbee2MQTT repository'
	git clone --depth 1 https://github.com/Koenkk/zigbee2mqtt.git ~/
	chown -R zigbee2mqtt: ~/

	einfo 'Create a virtualenv'
	python -m venv ~/.venv-live
	echo '. ~/.venv-live/bin/activate' >> ~/.bashrc
	echo '. ~/.venv-live/bin/activate' >> ~/.bash_profile
	
	. ~/.venv-live/bin/activate

	einfo 'Install node environment'
	python -m pip nodeenv

	einfo 'Init node environment'
	nodeenv -p -n 16.15.0

	einfo 'Deactivate and activate environment to be sure'
	deactivate
	. ~/.venv-live/bin/activate

	einfo 'Install dependencies'
	cd
	npm ci

#	ha_ver=$(pip list | grep ^zigbee2mqtt | awk '{print $2}')
#	mv ~/.venv-live ~/.venv-${ha_ver}
#	ln -s ~/.venv-${ha_ver} ~/.venv-live
fi
