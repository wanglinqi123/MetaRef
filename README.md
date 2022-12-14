# MetaRef: A pipeline for constructing reference genomes for large cohort-specific metagenome compression

## 1 Introduction

MetaRef is a pipeline for constructing specific reference genomes for large metagenome cohorts, and the generated reference genomes in FASTA format can be used to compress metagenomic sequencing data.

**Notification**: Current version only supports [PBS job management](https://albertsk.files.wordpress.com/2011/12/pbs.pdf) (`qsub`, `qstat`) and Paired-end reads analysis.

## 2 Installation

### 2.1 Install Requirements

You will need to download and install these packages before running MetaRef.

- Python: >= v3.6
  - Packages: metaphlan: v3.0.7
- Perl: \>=v5.26.2
- Softwares
  - fastp: v0.20.1
  - bwa: v0.7.17
  - samtools: v1.11
  - seqkit: v0.15.0

### 2.2 Prepare Database

You can build your own reference database using the reference genome of interest.  Alternatively, we recommend that you download the pre-built reference databases MetaPhlAn3_db_25k and Env_db_6k. 

For human metagenomic sequencing data, it is recommended to use MetaPhlAn3_db_25k. 

For environmental data, it is recommended to use both MetaPhlAn3_db_25k and Env_db_6k. 

- MetaPhlAn3_db_25k (When using this database, the following files need to be downloaded)
  - Reference
    - MetaPhlAn3_db_25k.fa
  - BWA index: indexed for MetaPhlAn3_db_25k
    - MetaPhlAn3_db_25k.fa.amb, MetaPhlAn3_db_25k.fa.ann, MetaPhlAn3_db_25k.fa.bwt, MetaPhlAn3_db_25k.fa.pac, MetaPhlAn3_db_25k.fa.sa
  - BWA shm: preloading index into memory
    - bwactl, bwaidx-MetaPhlAn3_db_25k.fa
- Env_db_6k  (When using this database, the following files need to be downloaded)
  - Reference
    - Env_db_6k.fa
  - BWA index: indexed for Env_db_6k
    - Env_db_6k.fa, Env_db_6k.fa.amb, Env_db_6k.fa.ann, Env_db_6k.fa.bwt, Env_db_6k.fa.pac, Env_db_6k.fa.sa
  - BWA shm: preloading index into memory
    - bwactl, bwaidx-Env_db_6k.fa

### 2.3 Install the pipeline

```
git clone https://github.com/wanglinqi123/MetaRef.git
cd MetaRef
```

## 3 Usage

### 3.1 Configuration Preparation

Please edit `sample.txt`, `ref.txt`, `config.yaml`, `cluster.yaml` files in `MetaRef` folder according to users' needs.

The most important parameters to edit:

- `sample.txt`: tab-delimited file path
- `ref.txt`: tab-delimited file path
- `config.yaml`
  - `fastp`: adapter_r1, adapter_r2
  - `ref_num`: number of reference sequences needs to be output
- `cluster.yaml`
  - `__default__`: queue
  - others: mem, cores

### 3.2 Run

```
###Use custom basic reference databases
#Step1: Build reference index for the basic reference database. For each database, this step will generate five files: *.amb, *.ann, *.bwt, *.pac, *.sa.
cd test_data/ref
bwa index ref_1.fa
bwa index ref_2.fa

#Step2???Preload reference index into RAM. This step will generate two files, bwactl and bwaidx-*, in the /dev/shm directory.
bwa shm ref_1.fa
bwa shm ref_2.fa
bwa shm -l #List names of indices in shared memory. If multiple databases are used at the same time, they must all be in shared memory.

#Step 3: Run MetaRef
sh work.sh &>work.out &

###Use pre-built basic reference databases
#Step1: Copy the preloaded indices to RAM
cp path/to/MetaPhlAn3_db_25k/bwactl /dev/shm
cp path/to/MetaPhlAn3_db_25k/bwaidx-MetaPhlAn3_db_25k.fa /dev/shm

#Step2: Run MetaRef
sh work.sh &>work.out &
```

## 4 Output

- 1.assay
  - `01.trimming`: trimmed metagenome fastq data
  - `02.align`: BAM alignment file
  - `03.filter`: temporary filtering file

- 2.result
  - `trim_summary.txt`: data information before and after trimming
  - `reference.fa`: cohort-specific reference genomes (depending on  `ref_num`)
  - `align_summary.txt`:  mapping information of reference genomes in  `reference.fa`
