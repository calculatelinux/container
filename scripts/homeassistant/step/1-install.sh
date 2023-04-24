#
# Функция configure() устанавливает Home Assistant
#
# Параметры:
# $1 = check - проверка обновлений, в противном случае установка или обновление
# $2 - возвращает имя модуля для перезагрузки в случае выполненного обновления
configure() {
	local action=$1
	local __result=$2

	local home_dir=/var/calculate/www/homeassistant
	local last_ver="$(get_last_ver homeassistant pip)"
	local work_dir="$home_dir/versions/homeassistant-$last_ver"
	local live_dir="$home_dir/homeassistant-live"
	local live_ver="$(get_live_ver $live_dir)"
	
	if [[ $action == 'check' ]]; then
		if [[ $live_ver == $last_ver ]]; then
			einfo "homeassistant: the latest version is installed $live_ver"
		else
			einfo "homeassistant: $last_ver update available, $live_ver installed"
			eval $__result=1 # наличие обновления
		fi
		return
	fi

	if [[ ! -e $home_dir ]]; then
		mkdir -p $home_dir/versions
		chmod 700 $home_dir
		chown homeassistant: $home_dir
	fi
	
	if [[ $live_ver != $last_ver ]]; then
		if [[ $live_ver != '' ]]; then
			echo Update Home Assistant
		else
			echo Install Home Assistant
		fi
	
		su - homeassistant -s /bin/bash -c "$(cat <<- EOF
			set -ueo pipefail
			export PATH="/lib/rc/bin:$PATH"
	
			ebegin 'Create a virtualenv'
			test -e $work_dir && rm -rf $work_dir
			python -m venv $work_dir
			source $work_dir/bin/activate
			eend
	
			ebegin 'Install all Python dependencies'
			python -m pip install wheel &>>/tmp/homeassistant.log
			eend
	
			ebegin 'Install Home Assistant $last_ver'
			pip install homeassistant==$last_ver &>>/tmp/homeassistant.log
			eend
	
			ebegin 'Install PostgreSQL dependencies'
			pip install psycopg2 &>>/tmp/homeassistant.log
			eend
	
			rm -f $live_dir
			ln -s $work_dir $live_dir
		EOF
		)"
	
		if [[ $live_ver != '' ]]; then
			eval $__result=homeassistant # демон который следует перезагрузить
		fi
	fi
}
