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
	local padding=2
	local margin=$(( $WIDTH - 13 - 14 - $padding ))
	margin=$(($margin / 2))
	printf "%-${margin}s"
	for (( i = 0; i < ${#tab_titles[@]}; i++ )); do
		if [ $SELECTED_TAB -eq $i ]; then
			echo -en $SELECTED
		fi
		if [ $CURSOR_IN_HEAD -eq $TRUE ] && [ $CURSOR_X -eq $i ]; then
			echo -en $CURSOR
		fi
		echo -en ${tab_titles[$i]}$RESET
		printf "%-${padding}s"
	done
}

function max_cx {
	if [ $CURSOR_IN_HEAD -eq $TRUE ]; then
		expr ${#tab_titles[@]} - 1
	else
		printf 2
	fi
}

function arr_contains {
	idx=$1
	shift
	for v in $@; do
		if [ $v -eq $idx ]; then
			printf $TRUE
			return
		fi
	done
	printf $FALSE
}

function min {
	local min=$1
	for v in $@; do
		if [ $v -lt $min ]; then
			min=$v
		fi
	done
	printf $min
}

function max_cy {
	if [ $CURSOR_X -eq 0 ]; then
		printf 5
	else
		printf 15
	fi
}

# $1:  horizontal  / vertical
# $2: left / right - up / down
function move_cursor {
	if [ $1 -eq $TRUE ]; then
		if [ $2 -eq $TRUE ] && [ $CURSOR_X -lt $(max_cx) ]; then
			let CURSOR_X=$CURSOR_X+1
			CURSOR_Y=$(min $CURSOR_Y $(max_cy))
		elif [ $2 -eq "$FALSE" ] && [ $CURSOR_X -gt 0 ]; then
			let CURSOR_X=$CURSOR_X-1
			CURSOR_Y=$(min $CURSOR_Y $(max_cy))
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
			elif [ $CURSOR_Y -lt $(max_cy) ]; then
				let CURSOR_Y=$CURSOR_Y+1
			fi
		fi
	fi
}

function switch_mod {
	for i in "${!SELECTED_MODS[@]}"; do
		if [[ ${SELECTED_MODS[$i]} -eq "$1" ]]; then
			unset 'SELECTED_MODS[$i]'
			return
		fi
	done
	SELECTED_MODS+=("$1")
}

SELECTED_MODS=()
SELECTED_FG=5
SELECTED_BG=8
function select_entry {
	if [ $CURSOR_IN_HEAD -eq $TRUE ]; then
		close
	else
		case $CURSOR_X in
			0) switch_mod $CURSOR_Y;;
			1) SELECTED_FG=$CURSOR_Y ;;
			2) SELECTED_BG=$CURSOR_Y ;;
		esac
	fi
}

# $1: whether to format mods
# $2: whether to format fg
# $3: whether to format bg
function format_selected {
	if [ $1 -eq $TRUE ]; then
		for mod in ${SELECTED_MODS[@]}; do
			printf "\e[%sm" ${codes[$mod]}
		done
	fi

	if [ $2 -eq $TRUE ]; then
		if [ $(($SELECTED_FG % 2)) -eq 0 ]; then
			printf "\e[3%sm" $(($SELECTED_FG  / 2))
		else
			printf "\e[9%sm" $((($SELECTED_FG - 1) / 2))
		fi
	fi
	if [ $3 -eq $TRUE ]; then
		if [ $(($SELECTED_BG % 2)) -eq 0 ]; then
			printf "\e[4%sm" $(($SELECTED_BG  / 2))
		else
			printf "\e[10%sm" $((($SELECTED_BG - 1) / 2))
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
			k | '[A') move_cursor $FALSE $TRUE ;;
			j | '[B') move_cursor $FALSE $FALSE ;;
			l | '[C') move_cursor $TRUE $TRUE ;;
			h | '[D') move_cursor $TRUE $FALSE ;;
			'') select_entry ;;
			#*) echo "-$mode-";;
		esac
	done
}

# $1: fg / bg
# $2: left start
# $3: selected entry (-1 for none)
function draw_16list {
	local names=( Black Red Green Yellow Blue Magenta Cyan Gray)
	local width=14
	[ $1 -eq $TRUE ] && pfxs=( 3 9 ) || pfxs=( 4 10 )
	for (( i = 0; i < 8; i++ )); do
		for pfx in ${pfxs[@]}; do
			printf "\n%-$2s"

			# set the other attributes
			if [ $1 -eq $FALSE ]; then
				if [ $i -eq 0 ]; then
					printf "\e[97m"
				else
					printf "\e[30m"
				fi
			fi
			#if [ $1 -eq $FALSE ]; then
			#	format_selected $TRUE $TRUE $FALSE
			#else
			#	format_selected $TRUE $FALSE $TRUE
			#fi

			# draw cursor:
			if [ $pfx -lt 5 ] && [ $3 -eq $(( $i * 2)) ]; then
				echo -ne $CURSOR
			elif [ $pfx -gt 5 ] && [ $3 -eq $(( $i * 2 + 1 )) ]; then
				echo -ne $CURSOR
			fi

			# draw text:
			echo -ne "\e[$pfx${i}m"
			if [ $pfx -lt 5 ]; then
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
codes=( 1 2 4 5 7 8 )
function draw_modlist {
	local mods=( Bold Dim Underlined Blink Invert Hidden )
	local width=12
	for ((i = 0; i < 6; i++)); do
		printf "\n"
		if [ $2 -eq $i ]; then
			printf $CURSOR
		fi
		if [ $(arr_contains $i ${SELECTED_MODS[@]}) -eq $TRUE ]; then
			printf "x"
		else
			printf " "
		fi
		printf "%2d: ${mods[$i]} \e[%dmText" ${codes[$i]} ${codes[$i]}
		printf $RESET
		if [ $2 -eq $i ]; then
			printf $CURSOR
		fi
		printf "%-$(($width - ${#mods[$i]}))s"
		printf $RESET
	done
}

function draw_preview {
	local padding=2
	local margin=$((($WIDTH - ${#PREVIEW} - $padding) / 2))

	printf "\n%-${margin}s"
	format_selected $TRUE $TRUE $TRUE
	printf "\e[24m"
	printf "%-$((${#PREVIEW} + 2 * $padding))s"
	printf "$RESET"

	printf "\n%-$(($margin))s"

	format_selected $TRUE $TRUE $TRUE
	printf "\e[24m%-${padding}s"

	format_selected $TRUE $TRUE $TRUE
	printf "${PREVIEW[@]}"

	printf "\e[24m%-${padding}s"
	printf "$RESET"

	printf "\n%-${margin}s"
	format_selected $TRUE $TRUE $TRUE
	printf "\e[24m%-$((${#PREVIEW} + 2 * $padding))s"
	printf "$RESET"
}

WIDTH=77 # width of the selection screen
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
	printf "\e[16A"
	if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 0 ]; then
		draw_modlist 1 $CURSOR_Y
	else
		draw_modlist 1 -1
	fi
	printf "\e[12B"
	draw_preview
}

function close {
	tput cvvis
	tput rmcup
	exit
}

tput smcup
tput civis
if [ command -v fortune &> /dev/null ]; then
	PREVIEW=$(fortune)
else
	PREVIEW="Lorem ipsum dolor sit amet"
fi
menu
