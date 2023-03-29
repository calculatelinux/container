#!/bin/bash

#set -ueo pipefail

SCRIPT=$(readlink -f $0)
[[ $UID == 0 ]] && exec su - mastodon -c "$SCRIPT"



. /var/db/repos/container/scripts/functions.sh
. /var/db/repos/calculate/scripts/ini.sh

set +u
source ~/.node-live/bin/activate
set -u
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd ~/live

get_variables(){
	SECRET_KEY_BASE=$(RAILS_ENV=production bundle exec rake secret)
	OTP_SECRET=$(RAILS_ENV=production bundle exec rake secret)
	vapid_array=($(RAILS_ENV=production bundle exec rake mastodon:webpush:generate_vapid_key))
	VAPID_PRIVATE_KEY=$(echo ${vapid_array[0]} | cut -d= -f2,3,4)
	VAPID_PUBLIC_KEY=$(echo ${vapid_array[1]} | cut -d= -f2,3,4)

	sed -i -E "s|(SECRET_KEY_BASE=).*|\1${SECRET_KEY_BASE}|g" ~/live/.env.production 
	sed -i -E "s|(OTP_SECRET=).*|\1${OTP_SECRET}|g" ~/live/.env.production
	sed -i -E "s|(VAPID_PRIVATE_KEY=).*|\1${VAPID_PRIVATE_KEY}|g" ~/live/.env.production
	sed -i -E "s|(VAPID_PUBLIC_KEY=).*|\1${VAPID_PUBLIC_KEY}|g" ~/live/.env.production
}

migrate_pgsql(){
	RAILS_ENV=production bundle exec rake db:setup
	RAILS_ENV=production bundle exec rake assets:precompile
	RAILS_ENV=production bin/tootctl accounts create ${ini[mastodon.login]} \
	--email ${ini[mastodon.smtp_from_address]} \
	--confirmed  --role Owner

	einfo Mail: ${ini[mastodon.smtp_from_address]} 
	einfo Login: ${ini[mastodon.login]}
}

check_migrate(){
	data=$(RAILS_ENV=production bundle exec rake db:migrate:status 2>/dev/null)
}

data={:-}

#if [[ -z $data ]]; then
	get_variables
	migrate_pgsql
#else 
	check_migrate
#fi
