## Script to plot a Manhattan plot from reading all the chunks from a folder for a phenotype
## Author: Jonathan Chan
#Create an empty ggplot to add points to
#Read in chunk to plot the plots to the empty ggplot
#Delete the chunk to free up RAM
#Repeat until all chunks (*clean.out) are added to the plot
#Print out the plot as a .png

# Plotting code from https://danielroelfs.com/blog/how-i-create-manhattan-plots-using-ggplot/

#----------------------------------------------------------------------
# Setup

library(ggplot2)
library(stringr)
library(readr)
library(haven)
library(dplyr)
library(ggrepel)

args <- commandArgs(trailingOnly=TRUE) #Allows taking of arguments in bash command line #By default you should pass the path (relative to the script)
chunk_file <- args

pheno <- str_match(chunk_file, 'output/(.+)_manhattan_rsid')[,2] #This assumes the format of output/phenoname_manhattan

#----------------------------------------------------------------------
#Import in the manhattan_chunk

import <- read_tsv(chunk_file, progress=T, col_types='ccnnccnnnnnnc')

#----------------------------------------------------------------------
#Plotting code function
manhattan.plot<-function(manhattan_tb, pheno) {
  
  most_sig <- import %>%
    mutate(rank = min_rank(pval)) %>%
    filter(rank <= 100) %>%
    select(-rank)
  
  write_tsv(most_sig,str_c('output/',pheno,'_100mostsig.tsv') )
  
  #manhattan_tb <- manhattan_tb %>%
    #mutate(chromosome = factor(chromosome, ordered=T))%>% #Makes chromosome ordered factor 
    #mutate(position = ifelse(any(position) > 1e6, position/1e6, position) ) #Ensure positions in Mbp
  
  cum_data <- manhattan_tb %>% 
    group_by(chromosome) %>% 
    summarise(max_pos = max(position)) %>% 
    mutate(pos_add = lag(cumsum(max_pos), default = 0)) %>% 
    select(chromosome, pos_add)
  
  manhattan_tb <- manhattan_tb %>% 
    inner_join(cum_data, by = "chromosome") %>% 
    mutate(cum_pos = position + pos_add) %>%
    mutate(Label = ifelse(pval < 5e-8, rsid, ''))
  
  #print(manhattan_tb)
  
  axis_set <- manhattan_tb %>% 
    group_by(chromosome) %>% 
    summarise(centre = median(cum_pos))
  
  #Compute the genomic inflation factor
  chisq <- qchisq(manhattan_tb$pval,1, lower.tail=F)
  #qchisq(assoc.df$P,1,lower.tail=FALSE) can convert p-value (even < 5.5e-17) to chisq
  # while qchisq(1-assoc.df$P,1) fails to convert small p-value (Inf in this case) 
  #As per https://bioinformaticsngs.wordpress.com/2016/03/08/genomic-inflation-factor-calculation/
  
  lambdagc <- round((median(chisq)/qchisq(0.5,1)), digits=3)
  

    
  manhattan <- ggplot(manhattan_tb, aes(x=cum_pos, y=-log10(pval), colour=as_factor(chromosome), size=-log10(pval)))+
    geom_point(alpha=0.75)+
    geom_hline(yintercept=-log10(5e-8), colour='grey40', linetype='dashed')+
    ylab('-log10 (p-value)')+
    xlab('Chromosome')+
    scale_x_continuous(label = axis_set$chromosome, breaks=axis_set$centre)+
    scale_color_manual(values = rep(c("#276FBF", "#183059"), unique(length(axis_set$chromosome)))) +
    labs(title=str_wrap(str_c('Manhattan plot for ', pheno)),
         caption=str_c('Genomic Inflation Factor: ', as.character(lambdagc)))+
    scale_size_continuous(range = c(0.5,3)) +
    theme_classic()+
    theme(legend.position='none')+
    #geom_label_repel(aes(label=Label), force=4, nudge_y=0.5)+
    scale_y_continuous(limits=c(0,10))
  
  if (min(manhattan_tb$pval, na.rm=T) < 1e-10){
    num_snps_removed <- sum(manhattan_tb$pval < 1e-10, na.rm=T)
    
    manhattan_fr <- manhattan +
      scale_y_continuous(limits=NULL)+
      labs(subtitle=str_c(as.character(num_snps_removed),' SNPs beyond e-10 range of plot'))
    
    ggsave(str_c('plots/',pheno,'_manhattan_fullrange.png'),plot=manhattan_fr, dpi=600,width=12, height=6)
  }
                         
  #Plotting a qqplot to check for abnormalities as per https://www.broadinstitute.org/files/shared/diabetes/scandinavs/qqplot.R
  observed <- sort(manhattan_tb$pval)
  lobs <- -(log10(observed))
  expected <- c(1:length(manhattan_tb$pval)) 
  lexp <- -(log10(expected / (length(expected)+1)))
  
  qqplot_df <- tibble(lobs, lexp)
  
  qqplot <- ggplot(qqplot_df, aes(y=lobs, x=lexp))+
    geom_line()+
    geom_abline(slope=1, intercept=0, col='red', linetype='dashed')+
    ylab('Observed -log10(pvalue)')+
    xlab('Expected -log10(pvalue)')+
    labs(title=str_wrap(str_c('QQplot for ', pheno, ' GWAS results')),
         caption=str_c('Genomic Inflation Factor: ', as.character(lambdagc)))+
    theme_classic()
  
  #print(manhattan)
  
  pvalhist <- ggplot(manhattan_tb)+
    geom_histogram(aes(x=pval), bins = 100)+
    scale_x_continuous(limits = c(0,1))+
    theme_classic()+
    ylab('Frequency')+
    xlab('p-value')+
    labs(title=str_wrap(str_c('p-value histogram for ', pheno, ' GWAS results')),
         caption=str_c('Genomic Inflation Factor: ', as.character(lambdagc)))
    
    
  
  ggsave(str_c('plots/',pheno,'_manhattan.png'),plot=manhattan, dpi=600,width=12, height=6)
  ggsave(str_c('plots/',pheno,'_qq.png'),plot=qqplot, dpi=600,width=9, height=6)
  ggsave(str_c('plots/',pheno,'_pvalhist.png'),plot=pvalhist, dpi=600,width=9, height=6)
    
  
}
  
#-------------------------------------------------------------------------------
#Code to run plot and output as .png

manhattan.plot(import, pheno)

