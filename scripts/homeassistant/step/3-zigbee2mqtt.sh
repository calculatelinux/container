#
# Функция configure() устанавливает Zigbee2MQTT
#
# Параметры:
# $1 = check - проверка обновлений, в противном случае установка или обновление
# $2 - возвращает имя модуля для перезагрузки в случае выполненного обновления
#
# Guide: https://www.zigbee2mqtt.io/guide/installation/07_python_virtual_environment.html
configure() {
	local action=${1:-}
	local __result=${2:-}

	local home_dir=/var/calculate/www/zigbee2mqtt
	local last_ver="$(get_last_ver Koenkk/zigbee2mqtt github)"
	local work_dir="$home_dir/versions/zigbee2mqtt-$last_ver"
	local live_dir="$home_dir/zigbee2mqtt-live"
	local live_ver="$(get_live_ver $live_dir)"
	local conf_dir="/var/calculate/zigbee2mqtt"

	# отобразим наличие обновления и выйдем
	if [[ $action == 'check' ]]; then
		if [[ $live_ver != $last_ver ]]; then
			einfo "zigbee2mqtt: $last_ver update available, $live_ver installed"
			eval $__result=1
		fi
		return 0
	fi

	# проверим на наличие устройства если сервис еще не настроен
	if [[ ! -e $conf_dir ]]; then
		if [[ -e /dev/ttyUSB0 ]]; then
			local file_dev=/dev/ttyUSB0
		elif [[ -e /dev/ttyACM0 ]]; then
			local file_dev=/dev/ttyACM0
		else
			return 0
		fi
	fi

	# выйдем если нет обновления
	[[ $live_ver == $last_ver ]] && return

	# подготовим пути
	if [[ ! -e $home_dir ]]; then
		mkdir -p ${home_dir}/versions
		chmod 700 $home_dir
		chown -R zigbee2mqtt: $home_dir
	fi
	if [[ ! -e $conf_dir ]]; then
		mkdir -p $conf_dir
		chmod 700 $conf_dir
		chown -R zigbee2mqtt: $conf_dir
	fi
	touch ${log_dir}/zigbee2mqtt.log
	chown zigbee2mqtt: ${log_dir}/zigbee2mqtt.log

	if [[ $live_ver == '' ]]; then
		echo Install Zigbee2MQTT
	else
		echo Update Zigbee2MQTT
	fi

	su - zigbee2mqtt -s /bin/bash -c "$(cat <<- EOF
		set -ueo pipefail
		export PATH="/lib/rc/bin:$PATH"

		ebegin Download zigbee2mqtt ${last_ver}
		test -e ${work_dir} && rm -rf ${work_dir} # удалим если было прервано
		wget -q https://github.com/Koenkk/zigbee2mqtt/archive/refs/tags/${last_ver}.zip \
		     -O zigbee2mqtt-${last_ver}.zip
		eend

		ebegin 'Extract the archive'
		unzip -q -d versions zigbee2mqtt-${last_ver}.zip
		rm zigbee2mqtt-${last_ver}.zip
		eend

		# вынесем настройки
		if [[ -z "$(ls -A $conf_dir)" ]]; then
			mv versions/zigbee2mqtt-${last_ver}/data/* ${conf_dir}
		fi
		rm -rf versions/zigbee2mqtt-${last_ver}/data
		ln -s ${conf_dir} versions/zigbee2mqtt-${last_ver}/data
		
		ebegin 'Create a virtualenv'
		python -m venv ${work_dir}/.venv
		eend
		
		ebegin 'Activate environment'
		source ${work_dir}/.venv/bin/activate
		eend
		
		ebegin 'Upgrade pip, wheel and setuptools'
		pip install --upgrade pip wheel setuptools &>>${log_dir}/zigbee2mqtt.log
		eend
		
		ebegin 'Install Node environment'
		pip install nodeenv &>>${log_dir}/zigbee2mqtt.log
		eend
		
		ebegin 'Init Node environment ${ini[zigbee2mqtt.nodeenv]}'
		nodeenv -p -n ${ini[zigbee2mqtt.nodeenv]} &>>${log_dir}/zigbee2mqtt.log
		eend
		
		einfo 'Install dependencies'
		cd ${work_dir}
		npm ci &>>${log_dir}/zigbee2mqtt.log
		cd

		ln -snf versions/zigbee2mqtt-${last_ver} $live_dir
	EOF
	)"

	if [[ $live_ver != '' ]]; then
		rc-service -s zigbee2mqtt restart
		echo
	else
		ebegin 'Setup zigbee2mqtt'
		mv ${conf_dir}/configuration.yaml ${conf_dir}/configuration.yaml.old
		cat > ${conf_dir}/configuration.yaml << EOF
# Home Assistant integration (MQTT discovery)
homeassistant: true

# allow new devices to join
permit_join: false

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://localhost'
  # MQTT server authentication, uncomment if required:
  user: ${ini[mosquitto.homeassistant_user]}
  password: '${ini[mosquitto.homeassistant_password]}'

# Serial settings
serial:
  # Location of USB sniffer
  port: ${file_dev}
frontend:
  port: 8080
  host: 127.0.0.1
EOF
		chown zigbee2mqtt: ${conf_dir}/configuration.yaml
		eend
	fi
}
