### linqiwang
### 2022-07-06

import pandas as pd
import sys

mapped_reads = sys.argv[1]
trim_summary = sys.argv[2]
ref_num = sys.argv[3]
output = sys.argv[4]

# Calculate the mappping rate and for each reference
# Mapping rate: Number of reads mapped to reference genome database / Number of total reads
df = pd.read_table(mapped_reads, sep = ' ', names = ['Ref_Name','Mapped_Reads'])
df = df.groupby('Ref_Name').sum().sort_values(by = ['Mapped_Reads'], ascending = False).reset_index()

total_reads = pd.read_table(trim_summary, sep = '\t')['Clean_reads_count'].sum()
df['Mapped_Reads/All_Mapped_Reads'] = (df['Mapped_Reads'].cumsum() / df['Mapped_Reads'].sum()).map(lambda x: format(x, '.2%'))
df['Mapped_Reads/All_Reads'] = (df['Mapped_Reads'].cumsum() / total_reads).map(lambda x: format(x, '.2%'))

df.index = df.index + 1 # Numbering reference from 1
df.index.name = 'No.' 

ref_mapping_rate = df.iloc[0:int(ref_num)]['Mapped_Reads'].sum() / total_reads
if  ref_mapping_rate<=0.1:
    print('Warning:The mapping rate of Top%d reference genomes to the database is less than 10%%. It is recommended to increase the number of reference genomes output or change the reference database.' %int(ref_num))
else:
    print('The reference genome has been successfully constructed. It contains %d genomes and has a mapping rate of %s to the database.'%(int(ref_num),format(ref_mapping_rate,'.2%')))
        
# Output the mapping results according to ref_num
df.iloc[0:int(ref_num)].to_csv(output, sep = '\t', index = True)
