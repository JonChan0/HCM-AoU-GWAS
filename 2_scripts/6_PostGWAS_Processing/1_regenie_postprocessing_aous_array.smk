'''
This pipeline performs downstream processing on AoUS .regenie outputs from Step 2
Author: Jonathan Chan
Date: 2024-11-04
'''

rule all:
    input:
        rsid_tsvs = expand("{regenie_filepath}{pheno}_step2_{pheno}_rsID_formatted.tsv", regenie_filepath=config['regenie_filepath'], pheno=config['pheno']),
        merged_tsv = config['regenie_filepath'] + 'formatted/'+ config['pheno'] +'_manhattan_rsid.tsv',
        lz_tsv = config['regenie_filepath'] + 'formatted/'+ config['pheno'] + '_lz.tsv'

rule rsID_mapper: #This requires internet access so needs to be run locally or on login node
    input:
        input_regenie="{regenie_filepath}{pheno}_step2_{pheno}.regenie"
    output:
        rsid_tsv="{regenie_filepath}{pheno}_step2_{pheno}_rsID.tsv"
    params:
        filter_snplist=config['plinkprep3_filter_snplist'],
        snps_only=config['snps_only'],
        output_folder=config['regenie_filepath']
    resources:
        mem_mb=8000
    conda:
        'R_4.3.3'
    shell:'''
        Rscript REGENIE_WGS_b38_to_rsID_mapper.R {input.input_regenie} {params.filter_snplist} {params.snps_only} {params.output_folder}
    '''

rule rsID_tsv_formatter:
    input: rules.rsID_mapper.output.rsid_tsv
    output:
        rsid_formatted_tsv="{regenie_filepath}{pheno}_step2_{pheno}_rsID_formatted.tsv"
    params:
        pheno = config['pheno'],
        output_folder=config['regenie_filepath'],
    resources:
        mem_mb=16000
    conda:
        'R_4.3.3'
    shell:'''
    Rscript REGENIE_WGS_manhattan_rsid_formatter.R {input} {params.pheno} {params.output_folder}
'''

rule perchr_merger:
    input:
        expand("{regenie_filepath}{pheno}_step2_{pheno}_rsID_formatted.tsv", regenie_filepath=config['regenie_filepath'], pheno=config['pheno'])
    output:
        config['regenie_filepath'] + 'formatted/'+ config['pheno'] + '_manhattan_rsid.tsv'
    params:
        input_folder = config['regenie_filepath']+ config['pheno'],
        pheno = config['pheno'],
        output_folder=config['regenie_filepath']+'formatted/'
    shell:'''
    cp {input} {output}
'''

rule lz_tsv_generator: #Column 10 for aous refers to p-value
    input: 
        rules.perchr_merger.output
    output:
        config['regenie_filepath'] + 'formatted/'+ config['pheno'] + '_lz.tsv'
    resources:
        mem_mb=16000
    shell:'''
        awk 'BEGIN {{ print "MarkerName\tP-value" }} NR > 1 {{ if (sub(/_.*/, "", $1))$1 = "chr"$1; print $1 "\t" $10 }}' {input} > {output}
    '''



        
