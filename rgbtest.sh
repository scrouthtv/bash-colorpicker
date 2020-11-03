#!/bin/bash

ISTEP=${ISTEP:-10}
JSTEP=${JSTEP:-4}
KSTEP=${KSTEP:-20}

let ROWS=264/$ISTEP

for ((k=0; k<255; k=$k+$KSTEP)); do
	for ((i=0;i<255;i=$i+$ISTEP)); do
		for ((j=0;j<255;j=$j+$JSTEP)); do
			printf "\e[48;2;%d;%d;%dm " $i $j $k
		done
		printf "\e[0m\n"
	done
	printf "\e[${ROWS}A"
done
printf "\e[${ROWS}B"
