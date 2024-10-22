#!/bin/bash

set -eo pipefail
export PATH="/lib/rc/bin:$PATH"

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - mastodon -c "$SCRIPT"


. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

cd ~/

if [[ ! -e ~/.node-live ]]
then
	einfo 'Install Node.js'
	cd ~
	nodeenv --node=${ini[mastodon.node]} .node-${ini[mastodon.node]%%.*}
	ln -sfT .node-${ini[mastodon.node]%%.*} .node-live
	set +u
	source .node-live/bin/activate
	set -u
	einfo 'Install yarn'
	npm install -g yarn
	corepack enable
	yarn set version classic
fi

if [[ ! -e ~/.rbenv ]]; then
	einfo 'Rbenv Setup: Get the code'
	git clone --single-branch --depth 1 https://github.com/rbenv/rbenv.git ~/.rbenv
	eend
fi

if [[ ! -e ~/.rbenv/plugins/ruby-build ]]; then
	einfo 'Ruby Setup: Get the code'
	git clone --single-branch --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
	eend
fi

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

if [[ ! -e ~/live ]]; then
	einfo 'Mastodon Setup: Get the code'
	git config --global advice.detachedHead false
	git clone -b v${ini[mastodon.git_tag]} --single-branch --depth 1 https://github.com/tootsuite/mastodon.git ~/live
	einfo 'Install Ruby'
	RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install ${ini[mastodon.ruby]}
	rbenv global ${ini[mastodon.ruby]}
	gem install bundler --no-document
	cd ~/live
	bundle config deployment 'true'
	bundle config without 'development test'
	einfo 'Install gems'
	bundle install -j$(nproc)
	eend
fi

