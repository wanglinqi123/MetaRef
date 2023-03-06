##########
# The script uses the accession number to download the genome sequence from NCBI 
# and constructs the Env_db_6k basic reference database (the MetaPhlAn3_db_25k is also built in the same way).
#
# This script requires NCBI's entrez direct tool (https://www.ncbi.nlm.nih.gov/books/NBK179288/).
##########

#!/bin/bash
if [ ! -d output ];then mkdir -p output;fi

for line in `cat Env_db_6k.ref.acc.list`;do
### Download reference genomes from GeneBank.
GenomePath=`esearch -db assembly -query $line|esummary|xtract -pattern DocumentSummary -element FtpPath_GenBank|head -n 1|awk -F "/" '{gsub(/ftp:/,"http:"); print $0"/"$NF"_genomic.fna.gz"}'`
wget -nc -q ${GenomePath}

### Replace the gaps in the genome with N base and join all segments into one long, complete sequence to construct the basic reference database.
GenomeName=`echo $GenomePath|awk -F "/" '{print $(NF-1)}'`
zcat ${GenomeName}_genomic.fna.gz|sed '1d'|sed '/^>/cNNNNNNNNNN'|sed '1 i\>'${GenomeName}'' >> output/Env_db_6k.DB.fa
echo ""${GenomeName}" finished."

rm -f ${GenomeName}_genomic.fna.gz
done
