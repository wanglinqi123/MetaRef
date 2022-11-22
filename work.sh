if [ ! -d 1.assay/cluster_logs ];then mkdir -p 1.assay/cluster_logs;fi

snakemake \
--snakefile rules/align.smk \
--configfile config.yaml \
--cluster-config cluster.yaml \
--jobs 50 \
--keep-going \
--rerun-incomplete \
--latency-wait 600 \
--cluster "qsub -V -cwd -q {cluster.queue} -l vf={cluster.mem},p={cluster.cores} -binding linear:{cluster.cores} -o {cluster.output} -e {cluster.error}"
