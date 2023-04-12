#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

test -e /etc/homeassistant/configuration.yaml && exit

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"
. homeassistant-live/bin/activate

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

hass --config /etc/homeassistant >/dev/null &
id_hass=$!

echo; einfon "Check for the first start Home Assistant "
while ! curl http://127.0.0.1:8123 2>/dev/null; do
	echo -n .
	sleep 1
done
kill $id_hass

cat >> /etc/homeassistant/configuration.yaml <<EOF

http:
  server_host: 127.0.0.1
  use_x_forwarded_for: true
  trusted_proxies: 127.0.0.1

recorder:
  db_url: postgresql://${ini[postgresql.homeassistant_user]}:${ini[postgresql.homeassistant_password]}@127.0.0.1/${ini[postgresql.homeassistant_database]}

panel_iframe:
  zigbee:
    title: Zigbee2mqtt
    url: ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]}/${ini[nginx.zigbee2mqtt_subpath]}
    icon: mdi:zigbee
  configurator:
    title: Configurator
    icon: mdi:wrench
    url: ${ini[homeassistant.protocol]}://${ini[homeassistant.domain]}/${ini[nginx.hass-configurator_subpath]}
EOF

echo
eend
