# Clear stdin before reading
clear_buf(){
	while read -r -t 0
		do read -r
	done
	read -t 0.01 -n 10000 || true
}

# Convert ini.env array to Python list
arr_to_list(){
	if [[ $# == 0 || -z $1 ]]
	then
		echo "[]"
		exit
	fi
	IFS=,
	local list=
	for i in $1; do
		if [[ -z $list ]]
		then
			list="'$i'"
		else
			list="$list, '$i'"
		fi
	done
	unset IFS
	list="[$list]"
	echo $list
}

get_last_ver(){
	local project=$1
	local hosting=$2
	case $hosting in
		pip)
			curl -s https://pypi.org/pypi/${project}/json | jq -r '.releases | keys[]' | grep -Ev [ab][0-9]+$ | tail -1
		;;
		github)
			curl -s https://api.github.com/repos/${project}/releases/latest | grep tag_name | cut -d '"' -f 4
		;;
	esac
}

get_live_ver(){
	if [[ ! -e $1 ]]; then
		exit
	fi
	local current_ver=$(readlink -f $1)
	echo ${current_ver##*-}
}
