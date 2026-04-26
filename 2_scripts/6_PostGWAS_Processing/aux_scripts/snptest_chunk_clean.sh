#!/bin/bash
# This defines the script that will be used to clean the .out files

#Obtain path - deprecated code that takes in user input instead of using argument
#read -p 'Path: ' path

#Assumes that the first argument after ./snptest_chunk_clean.sh is the path
path=$1

#For loop to run over each .out file

for f in "$path"/*[^clean].out
do
	echo "Cleaning {$f}"
	awk '{ if($21 != "NA" && $9 > 0.40 && $19 > 0.01) {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25}}' $f  | head -n -1> "${f%.out}_clean.out" 
  #Removes the last row which shows the 'completed'

done

