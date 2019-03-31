#!/bin/bash

args=("$@")									#	store arguments into the array
ELEMENTS=${#args[@]}						#	get number of arguments

if [ $ELEMENTS -eq 0 ]						#	no command line arguments
then
	resultC=($(sensors | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*C$' | tr '.' '\n' | grep -E '[0-9]$'))
	resultF=($(sensors -f | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*F$' | tr '.' '\n' | grep -E '[0-9]$'))

	count=${#resultC[@]}

	echo 'Temperatures'
	echo '------------'

	for (( i=0;i<$count;i++)); do
		valueC=${resultC[${i}]}				#	show core temparature in Celsius
		valueF=${resultF[${i}]}				#	show core temparature in Fahrenheits
		echo "    Core $i:  $valueC°C ($valueF°F)"
	done

	echo
	echo 'Fan information'
	echo '---------------'

	result=$(cat /proc/acpi/ibm/fan | grep -E 'status' | tr '\t' '\n' | grep -E 'led')	#	parse fan state value
	echo "    State:   $result"

	result=$(cat /proc/acpi/ibm/fan | grep -E 'speed' | tr '\t' '\n' | grep -E '[0-9]{2,}')		#	parse fan speed value
	echo "    Speed:   $result RPM"

	result=$(cat /proc/acpi/ibm/fan | grep -E 'level' | tr '\t' '\n' | grep -E '^[0-9]$')	#	parse fan level value
	echo "    Level:   $result"

	exit 0
fi

for (( i=0;i<$ELEMENTS;i++)); do 			#	iterate through all command line arguments
	argValue=${args[${i}]}					#	holds string value of actual argument in loop
	reLevel='^[1-7]{1}$'					#	regex which will match fan level value in range from 1 to 7

	if [ "$argValue" = "help" ] || [ "$argValue" = "-h" ] || [ "$argValue" = "-help" ] || [ "$argValue" = "--help" ]	#	show help information
	then
		echo 'DESCRIPTION'
		echo '  RichFan - Fan control program for ThinkPad laptops'
		echo
		echo 'USAGE'
		echo '  richfan       ->  show current temperatures and information about fan'
		echo '  richfan help  ->  show help information'
		echo '  richfan auto  ->  use automatic fan speed control'
		echo '  richfan min   ->  set fan speed to minimum allowed value'
		echo '  richfan max   ->  set fan speed to maximum allowed value'
		echo '  richfan N     ->  set desired fan level in range from 0 to 7'
		echo
		echo 'DEPENDENCIES'
		echo '  Package lm-sensors is required for fan control'
		echo '  Linux kernel with thinkpad-acpi is required'
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
	fi

	if [ "$argValue" = "min" ]
	then
		echo level 1 | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
	fi

	if [ "$argValue" = "max" ]
	then
		echo level 7 | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
	fi

	if [[ $argValue =~ $reLevel ]]			#	set desired level of fan in range from 1 to 7
	then
		echo level $argValue | sudo tee /proc/acpi/ibm/fan 	#	write value into the appropriate system file
	fi
done

exit 0
