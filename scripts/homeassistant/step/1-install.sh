#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - homeassistant -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

if [[ ! -e ~/.venv ]]; then
	einfo 'Create a virtualenv'
	cd ~
	python -m venv .venv
	echo 'source ~/.venv/bin/activate' >> ~/.bashrc
	source .venv/bin/activate

	einfo 'Install all Python dependencies'
	python -m pip install wheel

	einfo 'Install Home Assistant'
	pip install homeassistant
fi
