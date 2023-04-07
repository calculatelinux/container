#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

if [[ ! -e ~/.venv-live ]]; then
	einfo 'Create a virtualenv'

	python -m venv ~/.venv-live
	echo '. ~/.venv-live/bin/activate' >> ~/.bashrc
	echo '. ~/.venv-live/bin/activate' >> ~/.bash_profile
	
	. ~/.venv-live/bin/activate

	einfo 'Install all Python dependencies'
	python -m pip install wheel

	einfo 'Install Home Assistant'
	pip install homeassistant

	einfo 'Install PostgreSQL dependencies'
	pip install psycopg2

	ha_ver=$(pip list | grep ^homeassistant | awk '{print $2}')
	mv ~/.venv-live ~/.venv-${ha_ver}
	ln -s ~/.venv-${ha_ver} ~/.venv-live
fi
