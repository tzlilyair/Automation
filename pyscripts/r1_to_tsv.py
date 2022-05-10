# This script extract the barcode's sequence from the fastq files. 
# The code takes row number three out of the four rows (in the fastq file) and saves it in a new txt file that conclude list of the barcodes. 

import gzip
import sys
import os

with open(sys.argv[1], 'rt') as fastq:
    with open(sys.argv[2],'w') as out:
        lines=[]
        for line in fastq:
            lines.append(line)
            if len(lines)==4:
                out.write(lines[0][1:].split(" ")[0]+"\t"+lines[1][:16].strip()+'\n')
                lines=[]
