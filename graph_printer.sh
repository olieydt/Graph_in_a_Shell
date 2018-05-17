#!/bin/bash

#print a function at variable speed
#enter in f(x) = x^2

function row
{
    local COL
    local ROW
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo "${ROW#*[}"
}
function col
{
    local COL
    local ROW
    IFS=';' read -sdR -p $'\E[6n' ROW COL
    echo "${COL}"
}
function get_current_col
{
	row=$(row)
	#if [ "$row" = "54" ]; then
	((row = $row - 1))
	#fi
	col=0
}



function print_graph
{
	y_counter=20
	curr_row=$base_y
	tput cup $curr_row $center_x
	echo -n "^"
	while [[ "$y_counter" -ge "0" ]]; do
		((curr_row = $curr_row + 1))
		tput cup $curr_row $center_x
		echo -n "|"
		((y_counter = $y_counter - 1))
	done
	((curr_row = $base_y + 11))
	while [[ "$col" -lt "40" ]]; do
		tput cup $curr_row $col
		echo -n "--"
		((col = $col + 1))
	done
	echo -n ">"
}

function print_function
{
	formula="$1"
	counter=-10
	y_coords=()
	max_y=$((-2**31))
	#do the math
	while [[ "$counter" -lt 11 ]]; do
		#y_coord=$(echo "" | awk -v a="$counter" -v b="$power" 'END {print a ^ b}')
		formula_sub="${formula//x/($counter)}"
		y_coord=$(echo "" | awk 'END {print '"$formula_sub"' }')
		#echo $y_coord
		#sleep 1
		y_coords+=($y_coord)
		if [[ "${y_coord#-}" -gt "$max_y" ]]; then
			#set max coord to max y
			max_y=$y_coord
		fi
		((counter = $counter + 1))
	done
	#check if need to adjust proportion of axis
	prop=$(bc -l <<< "10 / ${max_y#-}")
	if (( $(echo "$prop < 1" | bc -l) )); then
		prop="0$prop"
	fi
	counter=0
	#echo $prop
	#sleep 1
	while [[ "$counter" -lt "21" ]]; do
		prop_y_coord=$(bc -l <<< "$prop * ${y_coords[$counter]}")
		if (( $(echo "$prop_y_coord < 0" | bc -l) )); then
			prop_y_coord="$prop_y_coord"
			prop_y_coord="${prop_y_coord//-./-0.}"
		elif (( $(echo "$prop_y_coord < 1" | bc -l) )); then
			prop_y_coord="0$prop_y_coord"
		fi
		print_at_coord $prop_y_coord $(($counter - 10))
		((counter = $counter + 1))
	done
}

function slow_print
{
	length="${#1}"
	counter=0
	while [[ "$length" -ne "0" ]]; do
		echo -n ${1:$counter:1}
		sleep 0.1
		((length = $length - 1))
		((counter = $counter + 1))
	done
}

#arguments are string to print, starting row, starting col of cursor and number of
#fade in and out
function fade_in_out
{
	length="${#1}"
	start_row=$2
	start_col=$3
	loops=$4
	counter=0
	while [[ "$counter" -lt $(( length * loops)) ]]; do
		tput cup $start_row $start_col
		echo -n " "
		sleep 0.07
		tput cup $start_row $start_col
		echo -n ${1:$((counter % length)):1}
		((counter = $counter + 1))
		start_col=$(( ( start_col + 1 ) % length ))
		sleep 0.02
	done
}

WIDTH=20
HEIGHT=10

function print_at_coord
{
	curr_y_coord=${1%.*}
	curr_x_coord=${2%.*}
	((y_coord = $base_y + (2 * $HEIGHT) - 9 - $curr_y_coord))
	((x_coord = $WIDTH + 2 \* $curr_x_coord))
	if [[ "${curr_y_coord#-}" -le "10" && "${curr_x_coord#-}" -le "10" ]]; then
		tput cup $y_coord $x_coord
		echo -n "x"
	fi
}

echo "Ok to clear terminal? Enter y/n:"
read ok
if [[ "$ok" = "y" ]]; then
	clear
else
	echo "Formatting of graph will suffer [8==D]"
fi

loader="Graphing..."
echo "What would you like to graph? Format as awk math"
read formula
get_current_col
slow_print "$loader"
fade_in_out "$loader" $row $col 2
echo ""

((row = $row + 1))
col=0
((base_y = $row + 1))
center_x=20

print_graph
print_function "$formula" 2>/dev/null

#bring cursor back down
tput cup $(expr $base_y + 2 \* $HEIGHT + 2) 0