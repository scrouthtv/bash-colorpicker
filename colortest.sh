#!/bin/bash

let BREAKAT=($(tput cols) - 2)/4

for i in {0..256}; do
	if [ $(expr $i % $BREAKAT) -eq 0 ]; then
		printf "\n "
	fi
	printf " \e[38;5;%03dm%03d\e[0m" $i $i
done

echo

for i in {0..256}; do
	if [ $(expr $i % $BREAKAT) -eq 0 ]; then
		printf "\n "
	fi
	printf " \e[48;5;%03dm%03d\e[0m" $i $i
done

printf "\n\n"
