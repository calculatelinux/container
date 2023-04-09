#!/bin/bash
# Guide: https://www.zigbee2mqtt.io/guide/installation/07_python_virtual_environment.html

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

test -e ~/zigbee2mqtt-live && exit

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - zigbee2mqtt -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd
ver=$(curl -s https://api.github.com/repos/Koenkk/zigbee2mqtt/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Latest Zigbee2MQTT version is ${ver}"
[[ -z $ver ]] && eerror 'The latest version of zigbee2mqtt is not defined!'

wget -q https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${ver}.zip -O zigbee2mqtt-${ver}.zip
einfo 'Extract the archive'
unzip -q -d versions zigbee2mqtt-${ver}.zip
rm zigbee2mqtt-${ver}.zip
ln -sf versions/zigbee2mqtt-${ver} zigbee2mqtt-live

if [[ -z "$(ls -A /var/calculate/zigbee2mqtt)" ]]; then
	mv versions/zigbee2mqtt-${ver}/data/* /var/calculate/zigbee2mqtt
	rmdir versions/zigbee2mqtt-${ver}/data
	ln -s /var/calculate/zigbee2mqtt versions/zigbee2mqtt-${ver}/data
fi

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

ebegin 'Setup zigbee2mqtt'
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
  # user: my_user
  # password: my_password

# Serial settings
serial:
  # Location of USB sniffer
  port: ${ini[zigbee2mqtt.dev]}
frontend: true
EOF
eend
