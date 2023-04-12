#!/bin/bash
# Guide: https://github.com/danielperna84/hass-configurator

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

test -e ~/hass-configurator-live && exit

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - hass-configurator -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd
ver=$(curl -s https://api.github.com/repos/danielperna84/hass-configurator/releases/latest | grep tag_name | cut -d '"' -f 4) && echo "Latest hass-configurator version is ${ver}"
[[ -z $ver ]] && eerror 'The latest version of hass-configurator is not defined!'

wget -q https://github.com/danielperna84/hass-configurator/archive/refs/tags/${ver}.zip -O hass-configurator-${ver}.zip
einfo 'Extract the archive'
unzip -q -d versions hass-configurator-${ver}.zip
rm hass-configurator-${ver}.zip
ln -sf versions/hass-configurator-${ver} hass-configurator-live

einfo 'Install python env'
python -m venv hass-configurator-live/.venv

einfo 'Activate environment'
. hass-configurator-live/.venv/bin/activate

einfo 'Upgrade pip and wheel'
pip install --upgrade pip wheel

einfo 'Install HASS Configurator'
pip install hass-configurator

echo '. ~/hass-configurator-live/.venv/bin/activate' >> .bashrc
echo '. ~/hass-configurator-live/.venv/bin/activate' >> .bash_profile

ebegin 'Setup HASS Configurator'
if [[ ! -e /etc/hass-configurator/settings.conf ]]; then
	cat > /etc/hass-configurator/settings.conf << EOF
{
	"LISTENIP": "0.0.0.0",
	"PORT": 3218,
	"GIT": false,
	"BASEPATH": null,
	"ENFORCE_BASEPATH": false,
	"SSL_CERTIFICATE": null,
	"SSL_KEY": null,
	"IGNORE_SSL": false,
	"HASS_API": "http://127.0.0.1:8123/api/",
	"HASS_WS_API": null,
	"HASS_API_PASSWORD": null,
	"USERNAME": null,
	"PASSWORD": null,
	"ALLOWED_NETWORKS": [],
	"ALLOWED_DOMAINS": [],
	"BANNED_IPS": [],
	"BANLIMIT": 0,
	"IGNORE_PATTERN": [],
	"DIRSFIRST": false,
	"SESAME": null,
	"SESAME_TOTP_SECRET": null,
	"VERIFY_HOSTNAME": null,
	"ENV_PREFIX": "HC_",
	"NOTIFY_SERVICE": "persistent_notification.create"
}
EOF
fi
eend
