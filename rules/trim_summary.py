import os
import argparse
import json
import pandas

def trim_stat(fastp_json):
    fastp_sample = os.path.basename(fastp_json).rstrip(".fastp.json")
    with open(fastp_json, 'r') as f:
        OA_json = json.load(f)
    reads_before = OA_json.get('summary').get('before_filtering').get('total_reads')
    bases_before = OA_json.get('summary').get('before_filtering').get('total_bases')
    read_len = OA_json.get('summary').get('before_filtering').get('read1_mean_length') #仅适用于PE
    q30_before = float(OA_json.get('summary').get('before_filtering').get('q30_rate'))*100
    duplication = float(OA_json.get('duplication').get('rate'))*100
    res_before = "%s\t%s\t%s\t%s\t%.2f%%\t%.2f%%\t" %(fastp_sample, reads_before, bases_before, read_len, q30_before, duplication)

    reads_pass = OA_json.get('summary').get('after_filtering').get('total_reads')
    bases_pass = OA_json.get('summary').get('after_filtering').get('total_bases')
    q30_after = float(OA_json.get('summary').get('after_filtering').get('q30_rate')) * 100
    reads_pass_ratio = reads_pass/reads_before * 100
    bases_pass_ratio = bases_pass/bases_before * 100
    res_after = "%s\t%.2f%%\t%.2f%%\t%s\t%.2f%%" %(reads_pass, reads_pass_ratio, q30_after, bases_pass, bases_pass_ratio)

    fastp_res = res_before + res_after
    print(fastp_res)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('infiles', nargs='+')
    args = parser.parse_args()

    print("Library_ID\tRaw_reads_count\tRaw_base_count\tRead_length\tRaw_Q30_ratio\tDuplication\tClean_reads_count\tClean_reads_ratio\tClean_Q30_ratio\tClean_bases_count\tClean_bases_ratio")
    for f in args.infiles:
        trim_stat(f)

main()
