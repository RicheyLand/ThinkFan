#!/bin/bash

args=("$@")										#	store arguments into the array
ELEMENTS=${#args[@]}							#	get number of arguments

resultC=($(sensors | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*C$' | tr '.' '\n' | grep -E '[0-9]$'))
resultF=($(sensors -f | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*F$' | tr '.' '\n' | grep -E '[0-9]$'))

fanState=$(cat /proc/acpi/ibm/fan | grep -E '^status' | tr '\t' '\n' | grep -E 'led')	#	parse fan state value
fanSpeed=$(cat /proc/acpi/ibm/fan | grep -E '^speed' | tr '\t' '\n' | grep -E '[0-9]+')		#	parse fan speed value
fanLevel=$(cat /proc/acpi/ibm/fan | grep -E '^level' | tr '\t' '\n' | grep -E '^[0-9]|auto$')	#	parse fan level value

if [ $ELEMENTS -eq 0 ]							#	no command line arguments
then
	count=${#resultC[@]}

	echo 'Temperatures'
	echo '------------'

	for (( i=0;i<$count;i++)); do
		valueC=${resultC[${i}]}					#	show core temperature in Celsius
		valueF=${resultF[${i}]}					#	show core temperature in Fahrenheits

		if [ ! -z "$valueC" ]					#	check if something has been parsed
		then
			echo "    Core $i:  $valueC°C ($valueF°F)"
		fi
	done

	echo
	echo 'Fan information'
	echo '---------------'

	if [ ! -z "$fanState" ]						#	check if something has been parsed
	then
		echo "    State:   $fanState"
	fi

	if [ ! -z "$fanSpeed" ]						#	check if something has been parsed
	then
		echo "    Speed:   $fanSpeed RPM"
	fi

	if [ ! -z "$fanLevel" ]						#	check if something has been parsed
	then
		echo "    Level:   $fanLevel"
	fi

	exit 0
fi

for (( i=0;i<$ELEMENTS;i++)); do 				#	iterate through all command line arguments
	argValue=${args[${i}]}						#	holds string value of actual argument in loop
	reLevel='^[1-7]{1}$'						#	regex which will match fan level value in range from 1 to 7

	if [ "$argValue" = "help" ] || [ "$argValue" = "-h" ] || [ "$argValue" = "-help" ] || [ "$argValue" = "--help" ]	#	show help information
	then
		echo 'DESCRIPTION'
		echo '  ThinkFan - Fan control program for ThinkPad laptops'
		echo
		echo 'USAGE'
		echo '  thinkfan        ->  show current temperatures and information about fan'
		echo '  thinkfan help   ->  show help information'
		echo '  thinkfan auto   ->  use automatic fan speed control'
		echo '  thinkfan min    ->  set fan speed to minimum allowed value'
		echo '  thinkfan max    ->  set fan speed to maximum allowed value'
		echo '  thinkfan N      ->  set desired fan level in range from 0 to 7'
		echo '  thinkfan temp   ->  print current temperatures'
		echo '  thinkfan state  ->  print current fan state value'
		echo '  thinkfan speed  ->  print current fan speed value'
		echo '  thinkfan level  ->  print current fan level value'
		echo
		echo 'DEPENDENCIES'
		echo '  Package lm-sensors is required for fan control'
		echo '  Linux kernel with thinkpad-acpi support is required'
		echo
		echo 'SETUP'
		echo '  Open this file as a root: /etc/modprobe.d/thinkpad_acpi.conf'
		echo '  Add this line: options thinkpad_acpi fan_control=1'
		echo '  Save changes and reboot computer'
		echo '  Run program'
		exit 0
	fi

	if [ "$argValue" = "auto" ] || [ "$argValue" = "0" ]
	then
		echo level auto | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argValue" = "min" ]
	then
		echo level 1 | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argValue" = "max" ]
	then
		echo level 7 | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
		exit 0
	fi

	if [[ $argValue =~ $reLevel ]]				#	set desired level of fan in range from 1 to 7
	then
		echo level $argValue | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argValue" = "temp" ] || [ "$argValue" = "temperature" ]  || [ "$argValue" = "thermal" ]
	then
		count=${#resultC[@]}

		for (( i=0;i<$count;i++)); do
			valueC=${resultC[${i}]}				#	show core temperature in Celsius
			valueF=${resultF[${i}]}				#	show core temperature in Fahrenheits

			if [ ! -z "$valueC" ]				#	check if something has been parsed
			then
				echo "$valueC°C ($valueF°F)"
			fi
		done

		exit 0
	fi

	if [ "$argValue" = "state" ] || [ "$argValue" = "status" ]
	then
		if [ ! -z "$fanState" ]					#	check if something has been parsed
		then
			echo "$fanState"
			exit 0
		fi
	fi

	if [ "$argValue" = "speed" ] || [ "$argValue" = "rate" ]
	then
		if [ ! -z "$fanSpeed" ]					#	check if something has been parsed
		then
			echo "$fanSpeed"
			exit 0
		fi
	fi

	if [ "$argValue" = "level" ]
	then
		if [ ! -z "$fanLevel" ]					#	check if something has been parsed
		then
			echo "$fanLevel"
			exit 0
		fi
	fi
done

exit 0
