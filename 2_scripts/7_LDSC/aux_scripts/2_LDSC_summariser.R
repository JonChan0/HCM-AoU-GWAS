#Script to summarise the LDSC outputs into a single .tsv including both hsq analysis and gcorr analysis files.
#Author: Jonathan Chan
#Date: 2024-06-20

library(tidyverse)

args <- commandArgs(trailingOnly=T)

if(length(args)==0){
  print('No arguments specified')
  stop()}

input_path <- args[1]

#Local test code
# input_path <- 'popgen/3_ldsc/output/ukb/'

#Detect .hsq .log files
hsq_files <- list.files(input_path, pattern='.hsq.log')
hsq_import <- map(hsq_files, ~readLines(str_c(input_path, ., collapse=''),warn=F) %>% str_c(collapse='\n'))
#Extract out the relevant details e.g hsq; lambda GC; ratio
hsq_phenos <- str_match(hsq_files,'^([^_]+)')[,2]
hsq_process <- map(hsq_import, ~str_match(.,'Total Observed scale h2: ([\\d\\.]+ \\([\\d\\.]+\\))')[,2])
lambda_process <- map(hsq_import, ~str_match(.,'Lambda GC: ([\\d\\.]+)')[,2] %>% as.numeric())
ratio_process <- map(hsq_import, ~str_match(.,'Ratio: ([\\d\\.]+)')[,2] %>% as.numeric())   #he value of ratio should be close to zero, though in practice values of 10-20% are not uncommon, probably due to sample/reference LD Score mismatch or model misspecification (e.g., low LD variants have slightly higher h^2 per SNP)
intercept_process <- map(hsq_import, ~str_match(.,'Intercept: ([\\d\\.]+)')[,2] %>% as.numeric())   #he intercept should be close to 1, unless the data have been GC corrected, in which case it will often be lower.

#Make hsq tibble
hsq_tb <- tibble(
  pheno = hsq_phenos,
  hsq = hsq_process,
  lambda = lambda_process, 
  ratio = ratio_process,
  intercept=intercept_process
) %>%
  mutate(hsq_se = str_match(hsq, '\\(([\\d\\.]+)\\)')[,2]) %>%
  mutate(hsq = str_match(hsq,'(^[\\d\\.]+)')[,2]) %>%
  dplyr::relocate(hsq_se, .after='hsq') %>%
  mutate(lambda=as.numeric(lambda),
         ratio = as.numeric(ratio),
         intercept=as.numeric(intercept))

write_tsv(hsq_tb, str_c(input_path, 'hsq_summary.tsv'))

#For .gcorr files------------------------------------

#Detect hsq.gcor files
gcorr_files <- list.files(input_path, pattern='.gcorr.log')
gcorr_import <- map(gcorr_files, ~readLines(str_c(input_path, ., collapse=''),warn=F) %>% str_c(collapse='\n'))
#Extract out the relevant details e.g r; z-score; p-value of gcorr
gcorr_pheno1 <- str_match(gcorr_files,'^([^_]+)')[,2]
gcorr_pheno2 <- str_match(gcorr_files,'\\.([^\\.]+)\\.gcorr')[,2]
r_process <- map(gcorr_import, ~str_match(.,'Genetic Correlation: ([-\\d\\.]+ \\([\\d\\.]+\\))')[,2])
z_process <- map(gcorr_import, ~str_match(.,'Z-score: ([-\\d\\.]+)')[,2] )
pval_process <- map(gcorr_import, ~str_match(.,'P: ([\\d\\.]+)')[,2])   #Ratio should be 0 but 0.1-0.2 i.e 10-20% fine as per Wiki

#Make hsq tibble
gcorr_tb <- tibble(
  pheno1 = gcorr_pheno1,
  pheno2 = gcorr_pheno2,
  r = r_process,
  z_score = z_process, 
  pval = pval_process
) %>%
  mutate(r_se = str_match(r, '\\(([\\d\\.]+)\\)')[,2]) %>%
  mutate(r = str_match(r,'(^[-\\d\\.]+)')[,2]) %>%
  dplyr::relocate(r_se, .after='r') %>%
  mutate(z_score=as.numeric(z_score),
         pval=as.numeric(pval))

write_tsv(gcorr_tb, str_c(input_path, 'gcorr_summary.tsv'))
