#!/bin/bash

let BREAKAT=${BREAKAT:-$((($(tput cols) - 2)/4))}
let START=16

for ((i = $START; i < 255; i++)); do
	if [ $(( ($i - $START) % $BREAKAT )) -eq 0 ]; then
		printf "\n "
	fi
	printf " \e[38;5;%03dm%03d\e[0m" $i $i
done

echo

for ((i = $START; i < 255; i++)); do
	if [ $(( ($i - $START) % $BREAKAT )) -eq 0 ]; then
		printf "\n "
	fi
	printf " \e[48;5;%03dm%03d\e[0m" $i $i
done

printf "\n\n"
