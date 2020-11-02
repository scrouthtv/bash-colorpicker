#!/bin/bash

TRUE=1
FALSE=0

SELECTED_TAB=0
CURSOR_IN_HEAD=1
CURSOR_X=0
CURSOR_Y=0

tab_titles=( "16 Color Mode" "256 Color Mode" )

function draw_tabs {
	for (( i = 0; i < ${#tab_titles[@]}; i++ )); do
		echo -n " "
		if [ $SELECTED_TAB -eq $i ]; then
			echo -en "\e[1m"
		fi
		if [ $CURSOR_IN_HEAD -eq $TRUE ] && [ $CURSOR_X -eq $i ]; then
			echo -en "\e[4m"
		fi
		echo -en ${tab_titles[$i]}"\e[0m"
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
		# TODO
		exit
	fi
}

# $1:  horizontal  / vertical
# $2: left / right - up / down
function move_cursor {
	if [ $1 -eq $TRUE ]; then
		if [ $CURSOR_IN_HEAD -eq $TRUE ]; then
			if [ $2 -eq $TRUE ] && [ $CURSOR_X -lt $(max_cx) ]; then
				let CURSOR_X=$CURSOR_X+1
			elif [ $2 -eq "$FALSE" ] && [ $CURSOR_X -gt 0 ]; then
				let CURSOR_X=$CURSOR_X-1
			fi
		else
			if [ $CURSOR_X -eq 0 ]; then
				true
			fi
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

function draw_16list {
	for (( i = 0; i < 8; i++ )); do
		if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 0 ] && [ $CURSOR_Y -eq $i ]; then
			echo -ne "\e[4m"
		fi
		echo -e "\e[3${i}m$i\e[0m"
	done
}

function draw {
	clear
	draw_tabs
	echo # separator
	draw_16list
}

tput smcup
menu
