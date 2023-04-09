#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

test -e ~/homeassistant-live && exit

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd
einfo 'Create a virtualenv'

python -m venv homeassistant-live
. homeassistant-live/bin/activate

einfo 'Install all Python dependencies'
python -m pip install wheel

einfo 'Install Home Assistant'
pip install homeassistant

einfo 'Install PostgreSQL dependencies'
pip install psycopg2

ha_ver=$(pip list | grep ^homeassistant | awk '{print $2}')
mv homeassistant-live versions/homeassistant-${ha_ver}
ln -sf versions/homeassistant-${ha_ver} homeassistant-live

echo '. ~/homeassistant-live/bin/activate' >> ~/.bashrc
echo '. ~/homeassistant-live/bin/activate' >> ~/.bash_profile
