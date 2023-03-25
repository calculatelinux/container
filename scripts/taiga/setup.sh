#!/bin/bash
# Install Taiga in Production
# https://docs.taiga.io/setup-production.html#_introduction

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"
. /var/db/repos/calculate/scripts/ini.sh

echo "Taiga setup"
chown taiga: /var/calculate/ini.env
su - taiga -c '/var/db/repos/container/scripts/taiga/install.sh'
/var/db/repos/container/scripts/taiga/postgresql.sh
/var/db/repos/container/scripts/taiga/rabbitmq.sh
/var/db/repos/container/scripts/taiga/config.sh
su - taiga -c '/var/db/repos/container/scripts/taiga/migrate.sh'

if [[ ! -e /etc/runlevels/default/taiga ]]; then
	cl-setup-system
	rc-update -u
fi
openrc
echo -e "\nAll is done! Open the link ${ini[taiga.protocol]}://${ini[taiga.taiga_sites_domain]} on your browser."
