#!/bin/bash

TRUE=1
FALSE=0

SELECTED_TAB=0
CURSOR_IN_HEAD=1
CURSOR_X=0
CURSOR_Y=0

SELECTED="\e[1m"
CURSOR="\e[7m"
RESET="\e[0m"

tab_titles=( "16 Color Mode" "256 Color Mode" )

function draw_tabs {
	for (( i = 0; i < ${#tab_titles[@]}; i++ )); do
		echo -n " "
		if [ $SELECTED_TAB -eq $i ]; then
			echo -en $SELECTED
		fi
		if [ $CURSOR_IN_HEAD -eq $TRUE ] && [ $CURSOR_X -eq $i ]; then
			echo -en $CURSOR
		fi
		echo -en ${tab_titles[$i]}$RESET
	done
}

function close {
	tput rmcup
	exit
}

function max_cx {
	if [ $CURSOR_IN_HEAD -eq $TRUE ]; then
		expr ${#tab_titles[@]} - 1
	else
		printf 5
	fi
}

# $1:  horizontal  / vertical
# $2: left / right - up / down
function move_cursor {
	if [ $1 -eq $TRUE ]; then
		if [ $2 -eq $TRUE ] && [ $CURSOR_X -lt $(max_cx) ]; then
			let CURSOR_X=$CURSOR_X+1
		elif [ $2 -eq "$FALSE" ] && [ $CURSOR_X -gt 0 ]; then
			let CURSOR_X=$CURSOR_X-1
		fi
		echo "new CX = $CURSOR_X" >> /tmp/picker.log
		max_cx >> /tmp/picker.log
	else
		if [ $2 -eq $TRUE ]; then
			if [ $CURSOR_Y -eq 0 ]; then
				CURSOR_IN_HEAD=$TRUE
			else
				let CURSOR_Y=$CURSOR_Y-1
			fi
		else
			if [ $CURSOR_Y -eq 0 ] && [ $CURSOR_IN_HEAD -eq $TRUE ]; then
				CURSOR_IN_HEAD=$FALSE
			else
				let CURSOR_Y=$CURSOR_Y+1
			fi
		fi
	fi
}

function menu {
	escape_char=$(printf "\u1b")
	while true; do
		draw
		read -rsn1 mode
		if [[ $mode == $escape_char ]]; then
			read -rsn2 mode
		fi
		case $mode in
			q) close ;;
			'[A') move_cursor $FALSE $TRUE ;;
			'[B') move_cursor $FALSE $FALSE ;;
			'[C') move_cursor $TRUE $TRUE ;;
			'[D') move_cursor $TRUE $FALSE ;;
			'') echo enter ;;
			#*) echo "-$mode-";;
		esac
	done
}

# $1: fg / bg
# $2: left start
# $3: column number
function draw_16list {
	names=( Black Red Green Yellow Blue Magenta Cyan Gray)
	width=14
	[ $1 -eq $TRUE ] && pfxs=( 3 9 ) || pfxs=( 4 10 )
	for (( i = 0; i < 8; i++ )); do
		for pfx in ${pfxs[@]}; do
			printf "\n%-$2s"
			if [ $1 -eq $FALSE ]; then
				if [ $i -eq 0 ]; then
					printf "\e[97m"
				else
					printf "\e[30m"
				fi
			fi
			if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq $3 ]; then
				if [ $pfx -lt 5 ] && [ $CURSOR_Y -eq $(( $i * 2)) ]; then
					echo -ne $CURSOR
				elif [ $pfx -gt 5 ] && [ $CURSOR_Y -eq $(( $i * 2 + 1 )) ]; then
					echo -ne $CURSOR
				fi
			fi
			echo -ne "\e[$pfx${i}m"
			if [ $pfx -eq 3 ]; then
				if [ $i -eq 7 ]; then
					printf " %3d: %-${width}s" $pfx$i "Light Gray"
				else
					printf " %3d: %-${width}s" $pfx$i "${names[i]}"
				fi
			else
				if [ $i -eq 7 ]; then
					printf " %3d: %-${width}s" $pfx$i "White"
				elif [ $i -eq 0 ]; then
					printf " %3d: %-${width}s" $pfx$i "Dark Gray"
				else
					printf " %3d: %-${width}s" $pfx$i "Light ${names[i]}"
				fi
			fi
			echo -ne $RESET
		done
	done
}

function draw {
	clear
	draw_tabs
	echo # separator
	draw_16list $FALSE 25 1
	printf "\e[16A"
	draw_16list $TRUE 1 0
}

tput smcup
menu
