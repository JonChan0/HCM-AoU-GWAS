#Script to convert per-chr. regenie file ID to rsID
#Author: Jonathan Chan
#Date: 2024-11-01

library(tidyverse)
library(SNPlocs.Hsapiens.dbSNP155.GRCh38) #Use this to map to rsID
library(BSgenome.Hsapiens.UCSC.hg38) #Use this to map the alleles against the reference genome

args <- commandArgs(trailingOnly = T)

regenie_file <- args[1]
filter_snplist <- args[2]
snps_only <- args[3]
output_folder <- args[4]

if (snps_only == 'True') {
  snps_only <- T
} else {
  snps_only <- F
}

#Import------------------------------------------

main <- function(regenie_file, filter_snplist, snps_only, output_folder) {
  print(str_c(
    'Reading in the .regenie GWAS summary statistics of ',
    regenie_file
  ))
  regenie <- read.table(regenie_file, header = T)

  #Filter the .regenie results for the snplist which passes QC filters (MAF/HWE/GENO) if not already filtered
  if (filter_snplist != 'NA') {
    snplist <- read_tsv(filter_snplist, col_names = 'ID')
    regenie <- filter(regenie, ID %in% snplist$ID)
  }

  if (isTRUE(snps_only)) {
    regenie <- regenie %>%
      filter(str_length(ALLELE0) == 1 & str_length(ALLELE1) == 1)
  }

  #Convert the hg38 coordinate to the rsID ---------------------------------------------------------
  regenie <- regenie %>%
    mutate(coords = str_c(CHROM, ':', GENPOS, '-', GENPOS))

  my_ranges <- GRanges(regenie$coords)
  genome <- BSgenome.Hsapiens.UCSC.hg38
  seqlevelsStyle(genome) <- "NCBI"

  print('Mapping the variants to rsID form from b38 genome coordinates')
  snps <- snpsByOverlaps(
    SNPlocs.Hsapiens.dbSNP155.GRCh38,
    my_ranges,
    genome = genome
  )
  #Output tibble corresponding to the mapped SNPS at the given positions
  mapped_snps_tb <- tibble(
    'chr' = as.numeric(as.character(seqnames(snps))),
    'pos' = as.numeric(as.character(ranges(snps))),
    # 'strand'=factor(strand(snps)),
    'rsID' = snps$RefSNP_id,
    'genome_ref_allele' = snps$ref_allele,
    'genome_alt_allele' = unstrsplit(snps$alt_alleles, sep = '|') #Multiple possible ALT alleles so makes it into a regexp
  )

  #Map to the original .regenie tb
  regenie <- regenie %>%
    select(-coords) %>%
    left_join(mapped_snps_tb, by = c('CHROM' = 'chr', 'GENPOS' = 'pos'))

  regenie <- regenie %>%
    mutate(rsID = ifelse(is.na(rsID), ID, rsID)) #If not mapped, just use the original ID

  #Double check alleles-----------------------------------------------------------
  #This double checks that the alleles match those in REGENIE

  regenie <- regenie %>%
    mutate(
      doublecheck = case_when(
        str_detect(ALLELE0, genome_ref_allele) ~ T,
        str_detect(ALLELE1, genome_alt_allele) ~ T,
        str_detect(ALLELE0, genome_alt_allele) ~ T, #In case of reverse order
        str_detect(ALLELE1, genome_ref_allele) ~ T, #In case of reverse order
        T ~ F
      )
    )

  print(sum(regenie$doublecheck == F))

  regenie <- regenie %>%
    filter(doublecheck == T) %>%
    select(-doublecheck)

  #Output-------------------------------------------------------------------
  basename <- str_match(basename(regenie_file), '([^\\.]+)\\.')[, 2]
  write_tsv(regenie, str_c(output_folder, '/', basename, '_rsID.tsv'))

  print(str_c('Written out ', output_folder, '/', basename, '_rsID.tsv'))
}

main(regenie_file, filter_snplist, snps_only, output_folder)

#Run over all chromosome files locally
#NEEDS TO RUN ON LOGIN NODE DUE TO INTERNET ACCESS REQUIREMENT
regenie_files <- list.files('./', pattern = '.regenie')
filter_snplist <- 'NA'
# filter_snplist <- '/well/PROCARDIS/jchan/HCM_GWAS_AoU/3_output/qc_ldpruned_snps_allchr.snplist'
snps_only <- T #Filter for only SNPs i.e remove indels
output_folder <- './'

walk(regenie_files, ~ main(., filter_snplist, snps_only, output_folder))
