#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - zigbee2mqtt -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

if [[ ! -e ~/zigbee2mqtt-live ]]; then
	cd
	einfo 'Clone Zigbee2MQTT repository'
	ver=$(curl -s https://api.github.com/repos/Koenkk/zigbee2mqtt/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Latest Zigbee2MQTT version is ${ver}"
	wget -q https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${ver}.zip -O zigbee2mqtt-${ver}.zip
	einfo 'Extract the archive'
	unzip -q -d versions zigbee2mqtt-${ver}.zip
	rm zigbee2mqtt-${ver}.zip
	ln -sf versions/zigbee2mqtt-${ver} zigbee2mqtt-live

	einfo 'Install python env'
	python -m venv zigbee2mqtt-live/.venv

	einfo 'Activate environment'
	. zigbee2mqtt-live/.venv/bin/activate

	einfo 'Upgrade pip, wheel and setuptools'
	pip install --upgrade pip wheel setuptools

	einfo 'Install node environment'
	pip install nodeenv

	einfo 'Init node environment'
	nodeenv -p -n ${ini[zigbee2mqtt.nodeenv]}

	einfo 'Install dependencies'
	cd zigbee2mqtt-live
	npm ci
	cd

	echo '. ~/zigbee2mqtt-live/.venv/bin/activate' >> .bashrc
	echo '. ~/zigbee2mqtt-live/.venv/bin/activate' >> .bash_profile

	einfo 'Setup zigbee2mqtt'
	mv zigbee2mqtt-live/data/configuration.yaml zigbee2mqtt-live/data/configuration.yaml.old
	cat > zigbee2mqtt-live/data/configuration.yaml << EOF
# Home Assistant integration (MQTT discovery)
homeassistant: false

# allow new devices to join
permit_join: true

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://localhost'
  # MQTT server authentication, uncomment if required:
  #   # user: my_user
  # password: my_password

# Serial settings
serial:
  # Location of USB sniffer
  port: ${ini[zigbee2mqtt.dev]}
EOF
fi
