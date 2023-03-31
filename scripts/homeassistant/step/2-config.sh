#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"
source .venv/bin/activate

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

hass >/dev/null &
id_hass=$!

echo; einfon "Check for the first start Home Assistant "
while ! curl http://127.0.0.1:8123 2>/dev/null; do
	echo -n .
	sleep 1
done
kill $id_hass

cat >> ~/.homeassistant/configuration.yaml <<EOF

http:
  server_host: 127.0.0.1
  use_x_forwarded_for: true
  trusted_proxies: 127.0.0.1
EOF

echo
eend
