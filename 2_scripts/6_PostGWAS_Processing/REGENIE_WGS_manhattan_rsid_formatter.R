#Script to format the rsid.tsv to manhattan_rsid.tsv and merge over all chromosomes
#Author: Jonathan Chan
#Date: 2024-11-05

library(tidyverse)

args <- commandArgs(trailingOnly=T)

input_path <- args[1]
pheno<-args[2]
output_folder <-args[3]


#Test code local
# input_folder <- './popgen/2_gwas/output/gwas/aous/hcm/formatted'
# pheno <- 'hcm'

#Import------------------------------------------
# filepaths <- list.files(input_folder, pattern='_rsID.tsv$')

print('Importing in per-chr rsID.tsv file')
# inputs <- map(filepaths, ~read_tsv(str_c(input_folder, '/',filepaths)))
input <- read_tsv(input_path)

# merged_output <- bind_rows(inputs)

#Process the per-tibble columns to match manhattan_rsid.tsv formatting

manhattan_rsid_formatter <- function(input_tb){
  
  output_tb <- input_tb %>%
    select(rsid=rsID, chromosome=CHROM, position=GENPOS, allele_A=ALLELE0, allele_B=ALLELE1, all_total=N, eaf=A1FREQ, pval=LOG10P, beta=BETA, beta_se=SE)%>%
    mutate(snid = str_c(as.character(chromosome),':',as.character(position)),
           maf = ifelse(eaf >= 0.5, 1-eaf,eaf)) %>%
    dplyr::relocate(snid, .after='rsid') %>%
    dplyr::relocate(maf, .after='eaf')
}

print('Converting to manhattan_rsid.tsv format')
# manhattan_rsid_output <- map(inputs, ~manhattan_rsid_formatter(.)) %>% bind_rows()
manhattan_rsid_output <- manhattan_rsid_formatter(input)
#Output-------------------------------------------------------------------

# write_tsv(merged_output,str_c(output_folder, '/', pheno, '_allchr_rsid.tsv'))

print('Writing out per-chr manhattan_rsid.tsv')
basename <- str_match(basename(input_path), '([^\\.]+)\\.')[,2]
write_tsv(manhattan_rsid_output,str_c(output_folder, '/', basename, '_formatted.tsv'))


