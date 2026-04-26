#!/bin/bash
#Script to prepare a file for reading into a snptest_manhattan.R to plot by merging all the *clean.out files and
#take only rsid chromosome, position and p-value
#I also include the code to output all the columns for a ${pheno}_gws.out for genome-wide significant loci

#Obtain path - deprecated
#read -p 'Path: ' path

path=$1
pheno=$2

#This defines the pheno name from the folder name with the input of output/?_gwas
#pheno="${path:10:${#path}}"#
#pheno="${pheno:0:(-5)}"
#echo "$pheno"

#Run over each .out file to append to manhattan.out (but need to make sure it's deleted first)
parent_dir="/well/PROCARDIS/jchan/hcmr_ukbb/gwas"

rm "${parent_dir}/output/${pheno}_manhattan.out"
rm "${parent_dir}/output/${pheno}_gws.out"

for f in "$path"/*clean.out
do
	echo "Appending chromosome; position; p-value and keeping GWS loci for "$f""
	#Only taking out the SNid, chromosome, position, alleleA, alleleB, info, MAF, pvalue, beta, beta_se
	awk  '(NR>1) {print $2,$3,$4,$5,$6,$9,$14,$15, $17,$19,$20}' $f >> "${parent_dir}/output/${pheno}_manhattan.out"
	#Removes the first row of column headings for each clean.out
	awk '{if ($17 < 0.00000005) {print}}' $f >> "${parent_dir}/output/${pheno}_gws.out"
	#Writing out the 100 most significant SNPs
	#awk '{if ($17 < 0.00000005) {print $2,$3,$4,$9,$15, $17,$19,$20}}}' $f >> "${parent_dir}/output/${pheno}_100sig.out"

done
