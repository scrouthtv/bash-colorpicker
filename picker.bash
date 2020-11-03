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
# $3: selected entry (-1 for none)
function draw_16list {
	names=( Black Red Green Yellow Blue Magenta Cyan Gray)
	width=14
	[ $1 -eq $TRUE ] && pfxs=( 3 9 ) || pfxs=( 4 10 )
	for (( i = 0; i < 8; i++ )); do
		for pfx in ${pfxs[@]}; do
			printf "\n%-$2s"

			# set foreground color on background:
			if [ $1 -eq $FALSE ]; then
				if [ $i -eq 0 ]; then
					printf "\e[97m"
				else
					printf "\e[30m"
				fi
			fi

			# draw cursor:
			if [ $pfx -lt 5 ] && [ $3 -eq $(( $i * 2)) ]; then
				echo -ne $CURSOR
			elif [ $pfx -gt 5 ] && [ $3 -eq $(( $i * 2 + 1 )) ]; then
				echo -ne $CURSOR
			fi

			# draw text:
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

# $1: left start
# $2: selected
function draw_modlist {
	mods=( Bold Dim Underlined Blink Invert Hidden )
	codes=( 1 2 4 5 7 8 )
	for ((i = 0; i < 6; i++)); do
		printf "\n"
		if [ $2 -eq $i ]; then
			printf $CURSOR
		fi
		printf " %2d: ${mods[$i]} \e[%dmText" ${codes[$i]} ${codes[$i]}
		printf $RESET
	done
}

function draw {
	#if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq $3 ]; then
	clear
	draw_tabs
	echo # separator
	if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 2 ]; then
		draw_16list $FALSE 51 $CURSOR_Y
	else
		draw_16list $FALSE 51 -1
	fi
	printf "\e[16A"
	if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 1 ]; then
		draw_16list $TRUE 25 $CURSOR_Y
	else
		draw_16list $TRUE 25 -1
	fi
	printf "\e[11A"
	if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 0 ]; then
		draw_modlist 1 $CURSOR_Y
	else
		draw_modlist 1 -1
	fi
}

tput smcup
menu
