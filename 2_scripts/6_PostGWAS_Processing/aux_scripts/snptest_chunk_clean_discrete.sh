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
	#Removing values with NA value for pvalue; IMPUTE INFO score < 0.4 and all_MAF < 0.01 i.e keeping the others

	awk '{ if($42 != "NA" && $9 > 0.40 && $29 > 0.01) {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$14,$15,$16,$17,$18,$29,$32,$42,$43,$44,$45,$46}}' $f  | head -n -1> "${f%.out}_clean.out" 
  #Removes the last row which shows the 'completed'

done

