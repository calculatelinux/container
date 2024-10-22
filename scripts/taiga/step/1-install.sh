#!/bin/bash

set -ueo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - taiga -c "$SCRIPT"

. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

if [[ ! -e ~/.node-live ]]; then
	einfo 'Install Node.js'
	cd ~
	nodeenv --node=${ini[taiga.node]} .node-${ini[taiga.node]%%.*}
	ln -sfT .node-${ini[taiga.node]%%.*} .node-live
fi

set +u
. ~/.node-live/bin/activate
set -u

if [[ ! -e ~/taiga-back ]]; then
	cd ~
	einfo 'Backend Setup: Get the code'
	git clone --branch stable --depth 1 https://github.com/kaleidos-ventures/taiga-back.git taiga-back
	cd taiga-back
	git checkout stable

	einfo 'Create a virtualenv'
	python -m venv .venv --prompt taiga-back
	source .venv/bin/activate
	pip install --upgrade pip wheel

	einfo 'Install all Python dependencies'
	pip install -r requirements.txt

	einfo 'Install taiga-contrib-protected'
	pip install git+https://github.com/kaleidos-ventures/taiga-contrib-protected.git@stable#egg=taiga-contrib-protected

	ebegin 'Copy the example config file'
	cp settings/config.py.prod.example settings/config.py
	eend
fi

if [[ ! -e ~/taiga-front-dist ]]; then
	cd ~
	einfo 'Frontend Setup: Get the code'
	git clone --branch stable --depth 1 https://github.com/kaleidos-ventures/taiga-front-dist.git taiga-front-dist
	cd taiga-front-dist
	git checkout stable

	ebegin 'Copy the example config file'
	cp ~/taiga-front-dist/dist/conf.example.json ~/taiga-front-dist/dist/conf.json
	eend
fi

if [[ ! -e ~/taiga-events ]]; then
	cd ~
	einfo 'Events Setup: Get the code'
	git clone --branch stable --depth 1 https://github.com/kaleidos-ventures/taiga-events.git taiga-events
	cd taiga-events
	git checkout stable

	einfo 'Install the required JavaScript dependencies'
	#source ~/.node-live/bin/activate
	npm install
	npm audit fix --force

	ebegin 'Create .env file based on the provided example'
	cp .env.example .env
	eend
fi

if [[ ! -e ~/taiga-protected ]]; then
	cd ~
	einfo 'Taiga protected Setup: Get the code'
	git clone --branch stable --depth 1 https://github.com/kaleidos-ventures/taiga-protected.git taiga-protected
	cd taiga-protected
	git checkout stable

	einfo 'Create a virtualenv'
	python -m venv .venv --prompt taiga-protected
	source .venv/bin/activate
	pip install --upgrade pip wheel

	einfo 'Install all Python dependencies'
	pip install -r requirements.txt

	ebegin 'Copy the example config file'
	cp ~/taiga-protected/env.sample ~/taiga-protected/.env
	eend
fi
