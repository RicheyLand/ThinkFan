#!/bin/bash

temps=($(cat /sys/class/thermal/thermal_zone*/temp 2> /dev/null))	#	get actual temperatures from system files

args=("$@")										#	store arguments into the array
ELEMENTS=${#args[@]}							#	get number of arguments
												#	get actual processor temperatures using lm-sensors package
resultC=($(sensors 2> /dev/null | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*C$' | tr '.' '\n' | grep -E '[0-9]$'))
resultF=($(sensors -f 2> /dev/null | grep -E 'Core' | tr ' ' '\n' | tr '\t' '\n' | tr '+' '\n' | grep -E '[0-9]' | grep -E '.*F$' | tr '.' '\n' | grep -E '[0-9]$'))

fanState=$(cat /proc/acpi/ibm/fan 2> /dev/null | grep -E '^status' | tr '\t' '\n' | grep -E 'led')	#	parse fan state value
fanSpeed=$(cat /proc/acpi/ibm/fan 2> /dev/null | grep -E '^speed' | tr '\t' '\n' | grep -E '[0-9]+')		#	parse fan speed value
fanLevel=$(cat /proc/acpi/ibm/fan 2> /dev/null | grep -E '^level' | tr '\t' '\n' | grep -E '^[0-9]|auto$')	#	parse fan level value

if [ $ELEMENTS -eq 0 ]							#	no command line arguments
then
	count=${#resultC[@]}
	tempsCount=${#temps[@]}
	newLine=false 								#	holds if newline should be printed
												#	lm-sensors package results have greatest priority
	if [ $count -gt 0 ]							#	temperatures was obtained using lm-sensors package
	then
		echo 'Temperatures'						#	print content header
		echo '------------'

		for (( i=0;i<$count;i++)); do 			#	iterate through the elements of list
			valueC=${resultC[${i}]}				#	show core temperature in Celsius
			valueF=${resultF[${i}]}				#	show core temperature in Fahrenheits

			if [ ! -z "$valueC" ]				#	check if something has been parsed
			then
				echo "    CPU $i:   $valueC°C ($valueF°F)"
			fi
		done

		newLine=true
	elif [ $tempsCount -gt 0 ]					#	temperatures was obtained using system files
	then
		types=($(cat /sys/class/thermal/thermal_zone*/type 2> /dev/null))	#	get device types from system files
		typesCount=${#types[@]}

		if [ $tempsCount -le $typesCount ]		#	handle index overflow
		then
			for (( i=0;i<$typesCount;i++)); do 	#	iterate through the elements of list
				value=${types[${i}]}

				if [ "$value" = "x86_pkg_temp" ]	#	handle only the CPU temperature
				then
					echo 'Temperatures'			#	print content header
					echo '------------'

					valueC=$(echo ${temps[${i}]} | head -c 2 2> /dev/null)
					valueF=$(echo "($valueC * 9/5) + 32" | bc 2> /dev/null)		#	convert temperature using appropriate formula
					echo "    CPU 0:   $valueC°C ($valueF°F)"
					newLine=true

					break
				fi
			done
		fi
	fi

	printState=false							#	holds if fan state value has been parsed
	printSpeed=false							#	holds if fan speed value has been parsed
	printLevel=false							#	holds if fan level value has been parsed

	if [ ! -z "$fanState" ]						#	check if fan state has been parsed
	then
		printState=true
	fi

	if [ ! -z "$fanSpeed" ]						#	check if fan speed has been parsed
	then
		printSpeed=true
	fi

	if [ ! -z "$fanLevel" ]						#	check if fan level has been parsed
	then
		printLevel=true
	fi

	if [ "$printState" = true ] || [ "$printSpeed" = true ] || [ "$printLevel" = true ]		#	check if something has been parsed
	then
		if [ "$newLine" = true ]				#	print newline if temperature section has been printed
		then
			echo
		fi

		echo 'Fan information'					#	print content header
		echo '---------------'

		if [ "$printState" = true ]				#	check if fan state has been parsed
		then
			echo "    State:   $fanState"
		fi

		if [ "$printSpeed" = true ]				#	check if fan speed has been parsed
		then
			echo "    Speed:   $fanSpeed RPM"
		fi

		if [ "$printLevel" = true ]				#	check if fan level has been parsed
		then
			echo "    Level:   $fanLevel"
		fi
	fi

	exit 0
elif [ $ELEMENTS -eq 1 ]						#	single command line argument
then
	argOne=${args[0]}							#	holds content of first command line argument
	reLevel='^[1-7]{1}$'						#	regex which will match fan level value in range from 1 to 7

	if [ "$argOne" = "help" ] || [ "$argOne" = "-h" ] || [ "$argOne" = "-help" ] || [ "$argOne" = "--help" ]	#	show help information
	then
		echo 'DESCRIPTION'
		echo '  ThinkFan - Fan control program for ThinkPad laptops'
		echo
		echo 'USAGE'
		echo '  thinkfan            ->  show current temperatures and information about fan'
		echo '  thinkfan help       ->  show help information'
		echo '  thinkfan auto       ->  use automatic fan speed control'
		echo '  thinkfan min        ->  set fan speed to minimum allowed value'
		echo '  thinkfan max        ->  set fan speed to maximum allowed value'
		echo '  thinkfan N          ->  set desired fan level in range from 0 to 7'
		echo '  thinkfan temp       ->  print current temperatures'
		echo '  thinkfan state      ->  print current fan state value'
		echo '  thinkfan speed      ->  print current fan speed value'
		echo '  thinkfan level      ->  print current fan level value'
		echo '  thinkfan timeout    ->  disable fan timeout'
		echo '  thinkfan timeout N  ->  set fan timeout in range from 0 to 120 seconds'
		echo '  thinkfan install    ->  perform required fan control installation'
		echo
		echo 'DEPENDENCIES'
		echo '  It is recommended to have lm-sensors package installed'
		echo '  Linux kernel with thinkpad-acpi support is required'
		echo
		echo 'SETUP'
		echo '  Run program with install option'
		echo '  Restart the computer'
		echo '  Run program'
		exit 0
	fi

	if [ "$argOne" = "auto" ] || [ "$argOne" = "0" ]
	then
		echo level auto 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argOne" = "min" ]
	then
		echo level 1 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argOne" = "max" ]
	then
		echo level 7 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null 	#	write value into the appropriate system file
		exit 0
	fi

	if [[ $argOne =~ $reLevel ]]				#	set desired level of fan in range from 1 to 7
	then
		echo level $argOne 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null 	#	write value into the appropriate system file
		exit 0
	fi

	if [ "$argOne" = "temp" ] || [ "$argOne" = "temperature" ]  || [ "$argOne" = "thermal" ]
	then
		count=${#resultC[@]}
		tempsCount=${#temps[@]}
												#	lm-sensors package results have greatest priority
		if [ $count -gt 0 ]						#	temperatures was obtained using lm-sensors package
		then
			for (( i=0;i<$count;i++)); do 		#	iterate through the elements of list
				valueC=${resultC[${i}]}			#	show core temperature in Celsius
				valueF=${resultF[${i}]}			#	show core temperature in Fahrenheits

				if [ ! -z "$valueC" ]			#	check if something has been parsed
				then
					echo "CPU $i:   $valueC°C ($valueF°F)"
				fi
			done
		elif [ $tempsCount -gt 0 ]				#	temperatures was obtained using system files
		then
			types=($(cat /sys/class/thermal/thermal_zone*/type 2> /dev/null))	#	get device types from system files
			typesCount=${#types[@]}

			if [ $tempsCount -le $typesCount ]	#	handle index overflow
			then
				for (( i=0;i<$typesCount;i++)); do 	#	iterate through the elements of list
					value=${types[${i}]}

					if [ "$value" = "x86_pkg_temp" ]	#	handle only the CPU temperature
					then
						valueC=$(echo ${temps[${i}]} | head -c 2 2> /dev/null)
						valueF=$(echo "($valueC * 9/5) + 32" | bc 2> /dev/null)		#	convert temperature using appropriate formula
						echo "CPU 0:   $valueC°C ($valueF°F)"

						break
					fi
				done
			fi
		fi

		exit 0
	fi

	if [ "$argOne" = "state" ] || [ "$argOne" = "status" ]
	then
		if [ ! -z "$fanState" ]					#	check if something has been parsed
		then
			echo "$fanState"
			exit 0
		fi
	fi

	if [ "$argOne" = "speed" ] || [ "$argOne" = "rate" ]
	then
		if [ ! -z "$fanSpeed" ]					#	check if something has been parsed
		then
			echo "$fanSpeed"
			exit 0
		fi
	fi

	if [ "$argOne" = "level" ]
	then
		if [ ! -z "$fanLevel" ]					#	check if something has been parsed
		then
			echo "$fanLevel"
			exit 0
		fi
	fi

	if [ "$argOne" = "timeout" ] || [ "$argOne" = "watchdog" ]
	then
		echo watchdog 0 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null
		exit 0
	fi

	if [ "$argOne" = "install" ]				#	install fan control program
	then 										#	content must be written into the system file before using fan control
		echo 'options thinkpad_acpi fan_control=1' | sudo tee /etc/modprobe.d/thinkpad_acpi.conf

		if [ $? -eq 0 ]
		then
			exit 0								#	file write was successful
		else
			exit 1								#	file write was unsuccessful
		fi
	fi

elif [ $ELEMENTS -eq 2 ]						#	two command line arguments
then
	argOne=${args[0]}							#	holds content of first command line argument
	argTwo=${args[1]}							#	holds content of second command line argument
	reTimeout='^[0-9]{1,3}$'					#	regex which will match timeout value in range from 0 to 120

	if [ "$argOne" = "timeout" ] || [ "$argOne" = "watchdog" ]
	then
		if [[ $argTwo =~ $reTimeout ]]			#	set desired timeout value in range from 0 to 120
		then
			if [ $argTwo -le 120 ]
			then
				echo watchdog $argTwo 2> /dev/null | sudo tee /proc/acpi/ibm/fan 2> /dev/null
				exit 0
			fi
		fi
	fi
fi

exit 0
