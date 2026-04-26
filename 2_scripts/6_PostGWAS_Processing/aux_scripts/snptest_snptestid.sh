#!/bin/bash
#This is a bash file to create a SNPtestid column as the final column for both _manhattan.out and _gws.out files 
#in the format of chromosome:position_alleleA_alleleB
#It takes input of the manhattan.out path as $1 and _gws.out path as $2

manhattan_path=$1
gws_path=$2
pheno_name=$3

parent_path="/well/PROCARDIS/jchan/hcmr_ukbb/gwas"

echo "Appending SNPtestid columns to ${pheno_name}_manhattan_snid.out"
awk '{$12=$1"_"$4"_"$5} 1' $manhattan_path | awk 'BEGIN{print "snid chromosome position allele_A allele_B info all_total maf pval beta beta_se full_snid"}1' > "${parent_path}/output/${pheno_name}_manhattan_snid.out"
#awk 'BEGIN{print "snid chromosome position allele_A allele_B info maf pval beta beta_se full_snid"}1' #This was code to add back the header

echo "Appending SNPtestid columns to ${pheno_name}_gws_snid.out"
awk '{$22=$1"_"$5"_"$6} 1' $gws_path | awk 'BEGIN{print "snid snid2 chromosome position allele_A alleleB index avg_max_post_call info all_AA all_AB all_BB all_NULL all_total maf missing_data_prop pval freq_add_info beta beta_se comment full_snid"}1' > "${parent_path}/output/${pheno_name}_gws_snid.out"
#awk 'BEGIN{print "snid snid2 chromosome position allele_A alleleB index avg_max_post_call info all_AA all_AB all_BB all_NULL all_total maf missing_data_prop pval freq_add_info beta beta_se comment full_snid"}1' #This was code to add back the header

echo "Removing the original files for $pheno_name"
rm $manhattan_path $gws_path
