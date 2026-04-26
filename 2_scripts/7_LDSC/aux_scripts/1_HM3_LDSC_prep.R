#This script converts the manhattan_rsid.tsv into HapMap3 filtered and LDSC columns .tsv

library(tidyverse)

args <- commandArgs(trailingOnly = T)

hm3_snplist_path <- args[1]
summstats_path <- args[2]
output_filename <- args[3]

#Import in the HM3 snplist
hm3_snps <- read_delim(hm3_snplist_path)

#Import in the summstats
print(str_glue('Reading in the {summstats_path}'))
summstats <- read_tsv(summstats_path, col_types = c('ccnnccnnnnnn'))

#Filter to HM3 snplist
summstats <- summstats %>%
  filter(rsid %in% hm3_snps$SNP)

#Filter to LDSC required columns
summstats <- summstats %>%
  select(
    SNP = rsid,
    N = all_total,
    beta,
    A1 = allele_B,
    A2 = allele_A,
    P = pval
  )

#Write out the .tsv file
print(str_glue(
  'Writing out the {output_filename}
'
))
write_tsv(summstats, output_filename)
