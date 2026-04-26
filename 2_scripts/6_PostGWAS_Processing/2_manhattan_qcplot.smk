'''
Snakemake pipeline to perform Manhattan and other QC plotting + LocusZoom plotting
Author: Jonathan Chan
Date: 2024-05-06

Input: ****_manhattan_rsid.tsv
Output: ****_manhattan & other. pngs
'''

from os import listdir
from os.path import isfile, join
from re import findall

#configfile: 'config.yaml'

tsv_basepath = config['tsv_basepath']
phenos = [f for f in listdir(tsv_basepath) if isfile(join(tsv_basepath, f))]
phenotype_list_list = [findall('(.+)_manhattan_rsid.tsv', p) for p in phenos] 
phenotype = [item for sublist in phenotype_list_list for item in sublist] 

#Define conditional outputs
outputs=[expand(config['plot_output_path'] + '{pheno}/' + '{pheno}_manhattan.png', pheno=phenotype),
    expand(config['plot_output_path'] + '{pheno}/' + '{pheno}_qq.png', pheno=phenotype),
    expand(config['plot_output_path'] + '{pheno}/' + '{pheno}_pvalhist.png', pheno=phenotype)
    ]

rule all:
    input:
        outputs

rule manhattan_qcplot:
    input: 
        manhattan_tsv = tsv_basepath + '{pheno}_manhattan_rsid2.tsv' if 'hcmr' in config['basepath'] else tsv_basepath + '{pheno}_manhattan_rsid.tsv'
    output:
        manhattan_plot = config['plot_output_path'] + '{pheno}/' + '{pheno}_manhattan.png',
        qqplot = config['plot_output_path'] + '{pheno}/' + '{pheno}_qq.png',
        pvalhist = config['plot_output_path'] + '{pheno}/' + '{pheno}_pvalhist.png'
    resources:
        mem_mb=64000
    params:
        output_plot_path = config['plot_output_path'] + '{pheno}/',
        pvalue_format=config['pvalue_format']
    shell:'''
        module purge 
        module use -a /apps/eb/2022b/skylake/modules/all
        module load R/4.2.2-foss-2022b
        Rscript aux_scripts/1_manhattan_qcplot.R {input.manhattan_tsv} {params.output_plot_path} {params.pvalue_format}
    '''