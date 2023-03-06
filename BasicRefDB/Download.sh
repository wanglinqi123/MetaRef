#!/bin/bash
##########################################################################################################################
# The script uses the accession number to download the genome sequence from NCBI                                         #
# for the construction of the Env_db_6k basic reference database (the MetaPhlAn3_db_25k is also built in the same way).  #
##########################################################################################################################

if [ ! -d output ];then mkdir -p output;fi

### Step1: Download reference genomes from GeneBank.
for line in `cat Env_db_6k.ref.acc.list`;do
GenomePath=`esearch -db assembly -query $line|esummary|xtract -pattern DocumentSummary -element FtpPath_GenBank|head -n 1|awk -F "/" '{gsub(/ftp:/,"http:"); print $0"/"$NF"_genomic.fna.gz"}'`
wget -nc -q ${GenomePath}

### Step2: Replace the gaps in the genome with N base and join all segments into one long, complete sequence to construct the basic reference database.
GenomeName=`echo $GenomePath|awk -F "/" '{print $(NF-1)}'`
zcat ${GenomeName}_genomic.fna.gz|sed '1d'|sed '/^>/cNNNNNNNNNN'|sed '1 i\>'${GenomeName}'' >> output/Env_db_6k.DB.fa
echo ""${GenomeName}" finished."
rm -f ${GenomeName}_genomic.fna.gz
done

### Step3: Build reference index for the basic reference database. This step will generate five files: *.amb, *.ann, *.bwt, *.pac, *.sa.
bwa index output/Env_db_6k.DB.fa
