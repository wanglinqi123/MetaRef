### linqiwang
### 2022-07-06

import pandas as pd
import os

configfile: "config.yaml"

def parse(tables_tsv):
    return pd.read_csv(tables_tsv, sep='\t').set_index("id", drop=False)

def get_sample_id(sample_df, wildcards, col):
    return sample_df.loc[wildcards.sample, [col]].dropna()[0]

def get_ref_id(ref_df, wildcards, col):
    return ref_df.loc[wildcards.ref, [col]].dropna()[0]

_samples = parse("sample.txt")
_refs = parse("ref.txt")

rule all:
    input:
        trim_summary = os.path.join(config["results"], "trim_summary.txt"),
        ref_summmary = os.path.join(config["results"], "align_summary.txt"),
        merged_ref = os.path.join(config["results"], "reference.fa")

### Step1: Trimming
rule trim:
    input:
        r1 = lambda wildcards: get_sample_id(_samples, wildcards, "fq1"),
        r2 = lambda wildcards: get_sample_id(_samples, wildcards, "fq2")
    output:
        trim_r1 = os.path.join(config["assay"]["trimming"], "{sample}.trimmed.1.fq.gz"),
        trim_r2 = os.path.join(config["assay"]["trimming"], "{sample}.trimmed.2.fq.gz"),
        html = os.path.join(config["assay"]["trimming"], "{sample}.fastp.html"),
        json = os.path.join(config["assay"]["trimming"], "{sample}.fastp.json")
    params:
        min_len = config["params"]["fastp"]["min_len"],
        n_lim = config["params"]["fastp"]["n_base_limit"],
        ad_r1 = config["params"]["fastp"]["adapter_r1"],
        ad_r2 = config["params"]["fastp"]["adapter_r2"]
    log:
        fastp_log = os.path.join(config["logs"]["trimming"], "{sample}.fastp.log")
    shell:
        '''
        fastp -i {input.r1} -I {input.r2} -o {output.trim_r1} -O {output.trim_r2} -w {threads} --n_base_limit {params.n_lim} --cut_front --cut_tail --length_required {params.min_len} --adapter_sequence={params.ad_r1} --adapter_sequence_r2={params.ad_r2} -j {output.json} -h {output.html} 2> {log.fastp_log}
        '''

### Step2: Trimming_summary
rule trim_summary:
    input:
        trim = expand(os.path.join(config["assay"]["trimming"], "{sample}.fastp.json"), sample = _samples.index)
    output:
        trim_summary = protected(os.path.join(config["results"], "trim_summary.txt"))
    shell:
        '''
        python rules/trim_summary.py {input.trim} > {output.trim_summary}
        '''

### Step3: Mapping reads to reference genome
rule align:
    input:
        trim_r1 = os.path.join(config["assay"]["trimming"], "{sample}.trimmed.1.fq.gz"),
        trim_r2 = os.path.join(config["assay"]["trimming"], "{sample}.trimmed.2.fq.gz")
    output:
        bam = os.path.join(config["assay"]["align"], "{sample}.{ref}.bam")
    params:
        ref_path = lambda wildcards: get_ref_id(_refs, wildcards, "path")
    threads:
        config["params"]["align"]["threads"]
    log:
        bwa_log = os.path.join(config["logs"]['align'], "{sample}.{ref}.log")
    shell:
        '''
        /hwfslv1_MGI_public/Software/bwa-0.7.17/bwa mem \
        -R '@RG\\tID:{wildcards.sample}\\tSM:{wildcards.sample}\\tLB:WGS\\tPL:Illumina' -t {threads} {params.ref_path} {input.trim_r1} {input.trim_r2} 2> {log.bwa_log}|samtools view -bS - > {output.bam}
        '''

### Step4: Filter reads
rule filter:
    input:
        bam = os.path.join(config["assay"]["align"], "{sample}.{ref}.bam")
    output:
        read_count_step1 = os.path.join(config["assay"]["filter"], "{sample}.{ref}.txt")
    shell:
        '''
        samtools view -F 260 {input.bam}|\
        awk '{{print $1,$3,$6,$12}}'|\
        awk '$3 !~/I|D|N|S|H|P/'|\
        awk '{{gsub(/[^0-9]+/, "", $4);print}}'|\
        awk '$4<=3' > {output.read_count_step1}
        '''

### Step5: Count mapped reads for each reference genome
rule count:
    input:
        expand(os.path.join(config["assay"]["filter"], "{{sample}}.{ref}.txt"), ref = _refs.index)
    output:
        read_count_step2 = os.path.join(config["assay"]["filter"], "{sample}.aligned.ref.txt")
    shell:
        '''
        cat {input}|\
        awk '{{++line[$2]}}END{{for(i in line){{print i,line[i]}}}}'|\
        sort -rnk 2 > {output.read_count_step2}
        '''

### Step6: Calculate the number of reads mapped to each reference genome & Merge and output reference genomes with the highest mapping rate
rule count_summary:
    input:
        read_count = expand(os.path.join(config["assay"]["filter"], "{sample}.aligned.ref.txt"), sample = _samples.index),
        trim_summary = os.path.join(config["results"], "trim_summary.txt"),
        ref_genome = expand("{ref}", ref = _refs["path"])
    output:
        read_count_summary = temp(os.path.join(config["results"], "read_count_summary.txt")),
        ref_summmary = protected(os.path.join(config["results"], "align_summary.txt")),
        ref_lst = temp(os.path.join(config["results"], "ref.list")),
        merged_ref = protected(os.path.join(config["results"], "reference.fa"))
    params:
        ref_num = config["params"]["ref_num"]
    shell:
        '''
        cat {input.read_count} > {output.read_count_summary}
        python rules/ref_summary.py {output.read_count_summary} {input.trim_summary} {params.ref_num} {output.ref_summmary}
        grep "GCA_" {output.ref_summmary}|awk '{{print $2}}'> {output.ref_lst}
        cat {input.ref_genome} | /hwfslv1_MGI_public/Users/wanglinqi/software/seqtk-1.3/seqtk subseq - {output.ref_lst} > {output.merged_ref}
        '''
