#!/bin/bash

set -eo pipefail
export PATH="/lib/rc/bin:$PATH"

if [[ $UID == 0 ]]
then
	exit
fi

source /var/db/repos/container/scripts/functions.sh
get_ini

if [[ ! -e ~/.node-live ]]
then
	einfo 'Install Node.js'
	cd ~
	nodeenv --node=$taiga_node .node-${taiga_node%%.*}
	ln -sfT .node-${taiga_node%%.*} .node-live
fi
source ~/.node-live/bin/activate

set -u

install_taiga_back(){
	cd ~
	einfo 'Backend Setup: Get the code'
	git clone https://github.com/kaleidos-ventures/taiga-back.git taiga-back
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
}

install_taiga_front_dist(){
	cd ~
	einfo 'Frontend Setup: Get the code'
	git clone https://github.com/kaleidos-ventures/taiga-front-dist.git taiga-front-dist
	cd taiga-front-dist
	git checkout stable

	ebegin 'Copy the example config file'
	cp ~/taiga-front-dist/dist/conf.example.json ~/taiga-front-dist/dist/conf.json
	eend
}

install_taiga_events(){
	cd ~
	einfo 'Events Setup: Get the code'
	git clone https://github.com/kaleidos-ventures/taiga-events.git taiga-events
	cd taiga-events
	git checkout stable

	einfo 'Install the required JavaScript dependencies'
	#source ~/.node-live/bin/activate
	npm install
	npm audit fix

	ebegin 'Create .env file based on the provided example'
	cp .env.example .env
	eend
}

install_taiga_protected(){
	cd ~
	einfo 'Taiga protected Setup: Get the code'
	git clone https://github.com/kaleidos-ventures/taiga-protected.git taiga-protected
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
}

#-----------------------------------------------------------------------------
# Запуск
#-----------------------------------------------------------------------------
[[ ! -e ~/taiga-back ]] && install_taiga_back

[[ ! -e ~/taiga-front-dist ]] && install_taiga_front_dist

[[ ! -e ~/taiga-events ]] && install_taiga_events

[[ ! -e ~/taiga-protected ]] && install_taiga_protected

exit 0

