''' Snakemake script to run LDSC pipeline for all traits in output/?_gwas folder involving
1) Munging via munge_sumstats.py
2) SNP-heritability estimation
3) Genetic correlation estimation with HCM disease state
'''

from os import listdir
from os.path import isfile, join
from re import findall

configfile: '7_config.yaml'

gwas_summstat_basepath = config['gwas_summstat_path'] #Path to the GWAS summary statistics
datasets= config['datasets']
output_path = config['output_path'] #Path to the output folder

#Writing the all rule which defines the final outputs of 1) hm3.sumstats.gzfile for each dataset,2) SNP-heritability estimation, 3) Genetic correlation estimation with HCM disease state
rule all:
    input: 
        expand(output_path+'{d}/{d}_ldsc.hm3.sumstats.gz', d=datasets), 
        expand(output_path+'{d}/{d}_ldsc.hsq.log', d=datasets), 
        expand(output_path+'{d}/{d}_ldsc.hcm.gcorr.log', d=datasets),
        output_path+'ldsc.array.srWGS.gcorr.log',
        output_path+'hsq_summary.tsv',
        output_path+'gcorr_summary.tsv'

#Filter the summstats to HapMap3 SNPs
rule filter_hm3:
    input: 
        hm3_snplist_path = config['hm3_snplist'],
        rsid_tsv = gwas_summstat_basepath+'{dataset}/formatted/hcm_manhattan_rsid.tsv'
    output:
        hm3_filtered_tsv = output_path+'{dataset}/hcm_manhattan_rsid_ldsc_hm3.tsv'
    resources:
        mem_mb=32000
    conda: 'R_4.3.3'
    shell:'''
        Rscript aux_scripts/1_HM3_LDSC_prep.R {input.hm3_snplist_path} {input.rsid_tsv} {output.hm3_filtered_tsv}
    '''
    
#Writing the rule to munge the GWAS summary statistics
rule munge:
    input: 
        script = config['munge_script'],
        hm3_filtered_tsv=rules.filter_hm3.output.hm3_filtered_tsv
    output: output_path+'{dataset}/{dataset}_ldsc.hm3.sumstats.gz'
    resources:
        mem_mb = 16000
    conda: 'ldsc'
    params:
        output_name= output_path+'{dataset}/{dataset}_ldsc.hm3',
        hm3_snplist = config['hm3_snplist']
    shell:'''
        python {input.script} \
        --sumstats {input.hm3_filtered_tsv} \
        --out {params.output_name} \
        --merge-alleles {params.hm3_snplist}
    '''

#Writing the rule to estimate SNP-heritability
rule snp_heritability:
    input:
        script = config['ldsc_script'],
        sumstats_gz = rules.munge.output
    output: output_path+'{dataset}/{dataset}_ldsc.hsq.log'
    resources:
        mem_mb = 16000
    conda: 'ldsc'
    params:
        output_name= output_path+'{dataset}/{dataset}_ldsc.hsq',
        ld_path = config['ld_folder']
    shell:'''
        python {input.script} \
        --h2 {input.sumstats_gz} \
        --ref-ld-chr {params.ld_path} \
        --w-ld-chr {params.ld_path} \
        --out {params.output_name}
    '''

#Writing the rule to estimate genetic correlation with HCM disease state
rule genetic_correlation:
    input: 
        script = config['ldsc_script'],
        sumstats_gz = rules.munge.output
    output: output_path+'{dataset}/{dataset}_ldsc.hcm.gcorr.log'
    resources:
        mem_mb = 16000
    conda: 'ldsc'
    params:
        input_name= output_path+'{dataset}/{dataset}_ldsc.hm3.sumstats.gz,'+config['tadros23_gwas_summstats'],
        output_name= output_path+'{dataset}/{dataset}_ldsc.hcm.gcorr',
        ld_path=config['ld_folder']
    shell:'''
        python {input.script} \
        --rg {params.input_name} \
        --ref-ld-chr {params.ld_path} \
        --w-ld-chr {params.ld_path} \
        --out {params.output_name}
        '''

#Run the genetic correlation between the array and srWGS_ACAF summstats
rule genetic_correlation_array_srWGS:
    input:
        script = config['ldsc_script'],
        sumstats_gz = expand(output_path+'{dataset}/{dataset}_ldsc.hm3.sumstats.gz', dataset=datasets)
    output: output_path+'ldsc.array.srWGS.gcorr.log'
    resources:
        mem_mb = 16000
    conda: 'ldsc'
    params:
        input_name= ','.join(expand(output_path+'{dataset}/{dataset}_ldsc.hm3.sumstats.gz', dataset=datasets)),
        output_name= output_path+'ldsc.array.srWGS.gcorr',
        ld_path=config['ld_folder']
    shell:'''
        python {input.script} \
        --rg {params.input_name} \
        --ref-ld-chr {params.ld_path} \
        --w-ld-chr {params.ld_path} \
        --out {params.output_name}
        '''

#Summarise the entire outputs
rule ldsc_summariser:
    input:
        expand(output_path+'{d}/{d}_ldsc.hsq.log', d=datasets), 
        expand(output_path+'{d}/{d}_ldsc.hcm.gcorr.log', d=datasets)
    output:
        hsq_summary=output_path+'hsq_summary.tsv',
        gcorr_summary=output_path+'gcorr_summary.tsv'
    params:
        input_path= output_path
    conda: 'R_4.3.3'
    resources:
        mem_mb=4000
    shell:'''
        Rscript aux_scripts/2_LDSC_summariser.R {params.input_path}
    '''
