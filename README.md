# GWAS for HCM in All of Us V8 (array & srWGS)

## Author: Jonathan Chan (jonathan.chan@rdm.ox.ac.uk)

This outlines the repository for the scripts only (.ipynb cleared outputs) from running GWAS for Hypertrophic cardiomyopathy in the All of Us Version 8 dataset.

## FYI

The path to the GWAS summary statistics are for

1) Array: 3_output/4_REGENIE/2_step2/array/
2) srWGS ACAF: 3_output/4_REGENIE/2_step2/srWGS_ACAF/

The path to all scripts used for the sample-level, variant-level QC, REGENIE preparation and REGENIE GWAS itself are in 2_scripts/

Note that the pvalue columns in the _rsID.tsv files including all files in the formatted/ subfolders refer to -log10(p-value).