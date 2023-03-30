#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd ~
timeout 5 /var/calculate/www/homeassistant/.venv/bin/hass || true

if ! grep -q http .homeassistant/configuration.yaml; then
	cat >> .homeassistant/configuration.yaml << EOF
http:
  use_x_forwarded_for: true
  trusted_proxies: 127.0.0.1
EOF
fi
