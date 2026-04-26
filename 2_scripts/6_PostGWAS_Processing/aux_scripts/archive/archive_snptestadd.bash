#!/bin/bash
# additive (1) analysis

chr=$1
start=$2
end=$3
sno=$4

pos="$chr:$start-$end"

echo -ne "$pos\n"

/gpfs0/apps/well/bgenix/bgen_v1.0-CentOS6.8-x86_64/bgenix -g \
    /well/PROCARDIS/agoel/hcm/wallthkmax/bgen/hcmr.p3.hrc.chr$chr.bgen -incl-range $pos | \
    /apps/well/snptest/2.5.4-beta3_CentOS6.6_x86_64_dynamic/snptest_v2.5.4-beta3 \
    -filetype bgen \
    -data - hcmr_gwas_phenos.sample \
    -o output_pend/echorest30_gwas/hcmr_add_$sno\_chr$chr\_$start\_$end.out \
    -frequentist 1 \
    -method score \
    -pheno echorest30 \
    -cov_names pc1 pc2 pc3 pc4 pc5 pc6 pc7 pc8 pc9 pc10 age sex height weight bsa




