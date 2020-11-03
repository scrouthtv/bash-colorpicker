#!/bin/bash

TRUE=1
FALSE=0

SELECTED_TAB=0
CURSOR_IN_HEAD=1
CURSOR_X=0
CURSOR_Y=0

SELECTED="\e[4m"
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
			printf $SELECTED
		fi
		if [ $CURSOR_IN_HEAD -eq $TRUE ] && [ $CURSOR_X -eq $i ]; then
			printf $CURSOR
		fi
		printf "${tab_titles[$i]}$RESET"
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

function max {
	local max=$1
	for v in $@; do
		if [ $v -gt $max ]; then
			max=$v
		fi
	done
	printf $max
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
		if [ $SELECTED_TAB -eq 0 ]; then
			printf 15
		else
			printf 255
		fi
	fi
}

# $1:  horizontal  / vertical
# $2: left / right - up / down
function move_cursor {
	if [ $1 -eq $TRUE ]; then
		if [ $2 -eq $TRUE ]; then
			if [ $SELECTED_TAB -eq 1 ] && [ $CURSOR_X -gt 0 ] &&
				[ $((($CURSOR_Y - 0) % 6)) -ne 3 ]; then # in the 256-color-list
				let CURSOR_Y=$CURSOR_Y+1 # move one entry to the right
			elif [ $CURSOR_X -lt $(max_cx) ]; then
				let CURSOR_X=$CURSOR_X+1
				[ $SELECTED_TAB -eq 1 ] && [ $CURSOR_X -gt 0 ] && let CURSOR_Y=$CURSOR_Y-5
				CURSOR_Y=$(min $CURSOR_Y $(max_cy))
				CURSOR_Y=$(max $CURSOR_Y 0)
				[ $CURSOR_IN_HEAD -eq $TRUE ] && select_entry
				#echo "we're going to the right" >> /tmp/picker.log
			fi
		else 
			if [ $SELECTED_TAB -eq 1 ] && [ $CURSOR_X -gt 0 ] &&
				[ $((($CURSOR_Y - 5) % 6)) -ne 5 ]; then # in the 256-color-list
				let CURSOR_Y=$CURSOR_Y-1 # move one entry to the left
			elif [ $CURSOR_X -gt 0 ]; then
				let CURSOR_X=$CURSOR_X-1
				[ $SELECTED_TAB -eq 1 ] && [ $CURSOR_X -gt 0 ] && let CURSOR_Y=$CURSOR_Y+5
				CURSOR_Y=$(min $CURSOR_Y $(max_cy))
				CURSOR_Y=$(max $CURSOR_Y 0)
				[ $CURSOR_IN_HEAD -eq $TRUE ] && select_entry
				#echo "we're going to the left" >> /tmp/picker.log
			fi
		fi
	else
		# up and down navigation:
		if [ $2 -eq $TRUE ]; then # up
			if [ $CURSOR_Y -eq 0 ]; then
				CURSOR_IN_HEAD=$TRUE # move to titlebar
				CURSOR_X=$SELECTED_TAB
			else
				if [ $SELECTED_TAB -eq 0 ] || [ $CURSOR_X -eq 0 ]; then
					let CURSOR_Y=$CURSOR_Y-1
				elif [ $CURSOR_Y -gt 6 ]; then
					let CURSOR_Y=$CURSOR_Y-6
				fi
			fi
		else
			if [ $CURSOR_Y -eq 0 ] && [ $CURSOR_IN_HEAD -eq $TRUE ]; then
				CURSOR_IN_HEAD=$FALSE
				CURSOR_X=0
			elif [ $SELECTED_TAB -eq 0 ] || [ $CURSOR_X -eq 0 ] && [ $CURSOR_Y -lt $(max_cy) ]; then
				let CURSOR_Y=$CURSOR_Y+1
			elif [ $SELECTED_TAB -eq 1 ] && [ $CURSOR_Y -lt $(($(max_cy) - 5)) ]; then
				let CURSOR_Y=$CURSOR_Y+6
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
		SELECTED_TAB=$CURSOR_X
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
# $4: format or print
function format_selected {
	if [ $4 -eq $TRUE ]; then
		pfx="\\"
	else
		pfx="\\\\"
	fi

	if [ $1 -eq $TRUE ]; then
		for mod in ${SELECTED_MODS[@]}; do
			printf "${pfx}e[%sm" ${codes[$mod]}
		done
	fi

	if [ $2 -eq $TRUE ]; then
		if [ $SELECTED_TAB -eq 0 ]; then
			printf "${pfx}e[%d%dm" $(fgtoi $TRUE $SELECTED_FG)
		else
			printf "${pfx}e[38;5;%dm" $SELECTED_FG
		fi
	fi
	if [ $3 -eq $TRUE ]; then
		if [ $SELECTED_TAB -eq 0 ]; then
			printf "${pfx}e[%d%dm" $(fgtoi $FALSE $SELECTED_BG)
		else
			printf "${pfx}e[48;5;%dm" $SELECTED_BG
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

# $1: pfx
# $2: i
function itofg {
	if [ $1 -lt 5 ]; then
		printf $(( $i * 2 ))
	else
		printf $(( $i * 2 + 1 ))
	fi
}

# $1: whether fg or bg
# $2: fg/bg value
function fgtoi {
	if [ $(($2 % 2)) -eq 0 ]; then
		if [ $1 -eq $TRUE ]; then
			printf "3 $(($2 / 2))"
		else
			printf "4 $(($2 / 2))"
		fi
	else
		if [ $1 -eq $TRUE ]; then
			printf "9 $((($2 - 1) / 2))"
		else
			printf "10 $((($2 - 1) / 2))"
		fi
	fi
}

# $1: pfx
# $2: i
function itoname {
	local names=( Black Red Green Yellow Blue Magenta Cyan Gray)
	if [ $1 -lt 5 ]; then
		if [ $2 -eq 7 ]; then
			#printf " %3d: %-${width}s" $1$2 "Light Gray"
			printf "Light Gray"
		else
			#printf " %3d: %-${width}s" $1$2 "${names[$2]}"
			printf "${names[$2]}"
		fi
	else
		if [ $2 -eq 7 ]; then
			#printf " %3d: %-${width}s" $1$2 "White"
			printf "White"
		elif [ $2 -eq 0 ]; then
			#printf " %3d: %-${width}s" $1$2 "Dark Gray"
			printf "Dark Gray"
		else
			#printf " %3d: %-${width}s" $1$2 "Light ${names[$2]}"
			printf "Light ${names[$2]}"
		fi
	fi
}

# $1: fg / bg
# $2: left start
# $3: selected entry (-1 for none)
function draw_16list {
	local width=14
	[ $1 -eq $TRUE ] && pfxs=( 3 9 ) || pfxs=( 4 10 )
	for (( i = 0; i < 8; i++ )); do
		for pfx in ${pfxs[@]}; do
			printf "\n%-$2s"
			let LINES=$LINES+1

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
			if [ $3 -eq $(itofg $pfx $i) ]; then
				printf $CURSOR
			fi

			if [ $1 -eq $TRUE ]; then
				if [ $SELECTED_FG -eq $(itofg $pfx $i) ]; then
					printf "$SELECTED"
				fi
			else
				if [ $SELECTED_BG -eq $(itofg $pfx $i) ]; then
					printf "$SELECTED"
				fi
			fi

			# draw text:
			printf "\e[$pfx${i}m"
			printf " %3d: %-${width}s" $pfx$i "$(itoname $pfx $i)"
			printf "$RESET"
		done
	done
}

#1: fg / bg
#2: left start
#3: selected entry
function draw_256list {
	printf $RESET
	if [ $1 -eq $TRUE ]; then
		pfx=38
	else
		pfx=48
	fi

	for ((i = -2; i <= 250; i = $i + 6)); do
		printf " \n%-$2s"
		let LINES=$LINES+1
		for ((j = 0; j < 6; j++)); do
			col=$(($i + $j))
			if [ $col -lt 0 ]; then
				printf "    "
				continue
			fi
			if [ $3 -eq $col ]; then
				printf " $CURSOR\e[%d;5;%dm%03d$RESET" $pfx $col $col
			else
				printf " \e[%d;5;%dm%03d$RESET" $pfx $col $col
			fi
		done
	done
}

# $1: left start
# $2: selected
codes=( 1 2 3 4 5 7 8 )
mods=( Bold Dim Cursive Underlined Blink Invert Hidden )
function draw_modlist {
	local width=12
	for ((i = 0; i < 6; i++)); do
		printf "\n"
		let LINES=$LINES+1
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
	let LINES=$LINES+1
	format_selected $TRUE $TRUE $TRUE $TRUE
	printf "\e[24m"
	printf "%-$((${#PREVIEW} + 2 * $padding))s"
	printf "$RESET"

	printf "\n%-$(($margin))s"
	let LINES=$LINES+1

	format_selected $TRUE $TRUE $TRUE $TRUE
	printf "\e[24m%-${padding}s"

	format_selected $TRUE $TRUE $TRUE $TRUE
	printf "${PREVIEW[@]}"

	printf "\e[24m%-${padding}s"
	printf "$RESET"

	printf "\n%-${margin}s"
	let LINES=$LINES+1
	format_selected $TRUE $TRUE $TRUE $TRUE
	printf "\e[24m%-$((${#PREVIEW} + 2 * $padding))s"
	printf "$RESET"
}

WIDTH=77 # width of the selection screen
function draw {
	#if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq $3 ]; then
	clear
	#printf "\e[${LINES}A"
	#printf "\e[1A\n"
	draw_tabs
	printf "\n" # separator
	let LINES=$LINES+1
	if [ $SELECTED_TAB -eq 0 ]; then
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
	elif [ $SELECTED_TAB -eq 1 ]; then
		if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 2 ]; then
			draw_256list $FALSE 51 $CURSOR_Y
		else
			draw_256list $FALSE 51 -1
		fi
		printf " $RESET\e[43A"
		if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 1 ]; then
			draw_256list $TRUE 25 $CURSOR_Y
		else
			draw_256list $TRUE 25 -1
		fi
		printf " $RESET\e[43A"
		if [ $CURSOR_IN_HEAD -eq $FALSE ] && [ $CURSOR_X -eq 0 ]; then
			draw_modlist 1 $CURSOR_Y
		else
			draw_modlist 1 -1
		fi
		printf "\e[39B"
	fi
	draw_preview
}

function squash-code {
	sed 's/m\\e\[/;/g' <<< $1 | tr -d '\n'
}

function close {
	tput cvvis
	tput rmcup
	printf "You selected"
	for i in "${!SELECTED_MODS[@]}"; do
		if [ $i -gt 0 ]; then
			printf ", %s" ${mods[${SELECTED_MODS[$i]}]}
		else
			printf " %s" ${mods[${SELECTED_MODS[$i]}]}
		fi
	done
	printf " text in "
	if [ $SELECTED_TAB -eq 0 ]; then
		pfxi=$(fgtoi $TRUE $SELECTED_FG)
		printf "%s" "$(itoname $pfxi)"
		printf " (%d%d)" $pfxi
	else
		printf "\e[38;5;%dm#%03d$RESET" $SELECTED_FG $SELECTED_FG
	fi

	printf " on "

	if [ $SELECTED_TAB -eq 0 ]; then
		pfxi=$(fgtoi $FALSE $SELECTED_BG)
		printf "%s" "$(itoname $pfxi)"
		printf " (%d%d)" $pfxi
	else
		printf "\e[48;5;%dm#%03d$RESET" $SELECTED_BG $SELECTED_BG
	fi

	printf ".\n"

	printf "The escape code for this combination is $SELECTED"
	squash-code $(format_selected $TRUE $TRUE $TRUE $FALSE)
	printf "$RESET .\n"
	exit
}

tput smcup
tput civis
clear
if [ command -v fortune &> /dev/null ]; then
	PREVIEW=$(fortune)
else
	PREVIEW="Lorem ipsum dolor sit amet"
fi
LINES=0
menu
