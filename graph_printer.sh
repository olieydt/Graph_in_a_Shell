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
	y_counter=0
	#as using two '-' to represent 1 unit
	x_counter=$(( (4 * SEL_X_AXIS) + 1 ))
	curr_row=$base_y
	tput cup $curr_row $(( 2 * $SEL_X_AXIS ))
	echo -n "^ f(x)"
	while [[ "$y_counter" -lt "$(( 2 * SEL_Y_AXIS ))" ]]; do
		((curr_row = $curr_row + 1))
		tput cup $curr_row $(( 2 * $SEL_X_AXIS ))
		echo -n "|"
		((y_counter = $y_counter + 1))
	done
	((curr_row = $base_y + SEL_Y_AXIS + 1))
	while [[ "$col" -lt "$x_counter" ]]; do
		tput cup $curr_row $col
		echo -n "-"
		((col = $col + 1))
	done
	echo -n "> x"
}


function add_label
{
	max_y="$1"
	start_row="$2"
	#print graph axis proportions
	tput cup $((base_y + SEL_Y_AXIS + 1)) $((2 * $(( 2 * $SEL_X_AXIS )) + 5))
	echo -n "1 unit per --"
	tput cup $start_row $(( 2 * $SEL_X_AXIS ))
	y_label=$(bc -l <<< "${max_y#-} / $SEL_Y_AXIS")
	#get first two non zero digits after decimal point
	length="${#y_label}"
	counter=0
	decimal=-1
	while [[ "$counter" -ne "$length" ]]; do
		digit=${y_label:$counter:1}
		((counter = $counter + 1))
		if [[ "$digit" = "." ]]; then
			((decimal = $counter + 1))
		elif [[ "$decimal" -ne "-1" && "$digit" -ne "0" ]]; then
			break
		fi
	done
	if [[ "$decimal" = "0" || "$counter" = "$length" ]]; then
		counter=$decimal
	fi
	echo -n ${y_label:0:counter} " per |"
}

function print_function
{
	formula="$1"
	print_speed="$2"
	counter=-$SEL_X_AXIS
	y_coords=()
	#max_y=$((-2**31))
	max_y=0
	#do the math
	while [[ "$counter" -lt $(( SEL_X_AXIS + 1 )) ]]; do
		#y_coord=$(echo "" | awk -v a="$counter" -v b="$power" 'END {print a ^ b}')
		formula_sub="${formula//x/($counter)}"
		y_coord=$(echo "" | awk 'END {print '"$formula_sub"' }')
		#echo $y_coord
		#sleep 1
		y_coords+=($y_coord)
		if (( $(echo "${y_coord#-} > ${max_y#-}" | bc -l) )); then
			#set max coord to max y
			max_y=$y_coord
		fi
		((counter = $counter + 1))
	done
	#check if need to adjust proportion of axis
	prop=$(bc -l <<< "$SEL_Y_AXIS / ${max_y#-}")
	if (( $(echo "$prop < 1" | bc -l) )); then
		prop="0$prop"
	fi
	#add label to axis and value
	add_label $max_y $row
	counter=0
	while [[ "$counter" -lt "$(( (2 * SEL_X_AXIS) + 1 ))" ]]; do
		prop_y_coord=$(bc -l <<< "$prop * ${y_coords[$counter]}")
		if (( $(echo "$prop_y_coord < 0" | bc -l) )); then
			prop_y_coord="$prop_y_coord"
			prop_y_coord="${prop_y_coord//-./-0.}"
		elif (( $(echo "$prop_y_coord < 1" | bc -l) )); then
			prop_y_coord="0$prop_y_coord"
		fi
		print_at_coord $prop_y_coord $((counter - SEL_X_AXIS))
		#vary speed of print
		sleep $(bc -l <<< "$print_speed / 50")
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

function print_at_coord
{
	curr_y_coord=${1%.*}
	#echo $curr_y_coord
	curr_x_coord=${2%.*}
	y_coord=$((base_y + (2 * SEL_Y_AXIS) - (SEL_Y_AXIS - 1) - curr_y_coord))
	#echo $y_coord
	#sleep 5
	x_coord=$(((2 * SEL_X_AXIS) + 2 * curr_x_coord))
	if [[ "${curr_y_coord#-}" -le "$SEL_Y_AXIS" && "${curr_x_coord#-}" -le "$SEL_X_AXIS" ]]; then
		tput cup $y_coord $x_coord
		echo -n "x"
	fi
}

#start parsing arguments
SEL_Y_AXIS=10
SEL_X_AXIS=10
counter=1
re='^[0-9]+$'
cleared_screen=0
while [[ -n ${!counter} ]]; do
	flag=${!counter}
	((counter = $counter + 1))
	argument=${!counter}
	if [[ "$flag" = "-x" && "$argument" =~ $re ]]; then
		SEL_X_AXIS=$argument
	elif [[ "$flag" = "-y" && "$argument" =~ $re ]]; then
		SEL_Y_AXIS=$argument
	elif [[ "$flag" = "-s" && "$argument" =~ $re ]]; then
		print_speed=$argument
	elif [[ "$flag" = "-c" ]]; then
		cleared_screen=1
	elif [[ "$flag" = "-h" ]]; then
		echo -e "Usage: \t -x for x axis length \n\t -y for y axis length \n\t -c clear terminal window (should be used to help formatting)\n\t -s print speed (1 to 10, fastest to slowest)\n\t -h help"
		exit
	else
		echo "Use -h for help"
		exit
	fi
	if [[ "$argument" =~ $re ]]; then
		((counter = $counter + 1))
	fi
done

#check that not empty
if (( ! $((counter - 1)) )); then
	echo "Use -h for help"
	exit
fi

#if [[ "$2" -gt "5" && "$1" -gt "5" ]]; then
#		SEL_X_AXIS="$1"
#		SEL_Y_AXIS="$2"
#fi

#echo "ok to clear terminal? Enter y/n:"
#read ok
#if [[ "$ok" = "y" ]]; then
if (( $cleared_screen )); then
	clear
else
	echo "Should use -c to clear terminal, otherwise formatting of graph will suffer [8==D]"
fi

loader="Graphing..."
echo "What would you like to graph? Format as awk math. ex: cos (0.5 * x)"
read formula
#echo "What print speed? Enter 1 to 10 (fastest to slowest)"
#read print_speed
get_current_col
slow_print "$loader"
fade_in_out "$loader" $row $col 1
echo ""

((row = $row + 1))
col=0
((base_y = $row + 1))

print_graph
print_function "$formula" "$print_speed" #2>/dev/null

#bring cursor back down
tput cup $(expr $base_y + 2 \* $SEL_Y_AXIS + 2) 0