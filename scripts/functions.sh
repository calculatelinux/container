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
