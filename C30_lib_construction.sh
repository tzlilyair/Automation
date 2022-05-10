#!/bin/bash
#Description: This script extract the 17 unique and the barcodes from the full sequence of the fastq files.
#This script use Cutadapt,Bowtie and Samtools. All this programs help us to do trimming to the sequence and to do alingment to the library.

#Example:
# The full sequence: TGCGATCTAAGTAAGCTTGCCTGCATTAAAGGTCAGGTACTGTTGGTAAACCAGCTCCGTGAGACGGATTTGAGGATCCCCAGCTCGCCACCATGGTGTCTAA
# adapter 1: TGCGATCTAAGTAAGCTTG
# 17 unique: CCTGCATTAAAGGTCAG
# adapter 2: GTACTGTTGGTAAACCAGCTC
# barcode: CGTGAGACGGATTTGA
# leftover: GGATCCCCAGCTCGCCACCATGGTGTCTAA

experiment_name=$1
cell_line_name=$2
replicate_name=$3
file=$4
pyscripts_folder=$5
bowtie2_referece_folder=$6
define_local_exec_paths_file=$7
output_root_dir=$8

sample_folder=$output_root_dir/$experiment_name/$cell_line_name/$replicate_name


# to run on cluster:
module load hurcs
module load cutadapt/3.4
#source $define_local_exec_paths_file

mkdir -p $sample_folder/17_unique/cutadapt
mkdir -p $sample_folder/17_unique/alignment
mkdir -p $sample_folder/barcodes/cutadapt

# 17 unique
cutadapt -j 0 -g TGCGATCTAAGTAAGCTTG -a GTACTGTTGGTAAACCAGCTC -m 17 -M 17 -O 3 -n 2 -o $sample_folder/17_unique/cutadapt/clipped_17_unique_output.fastq --untrimmed-output $sample_folder/17_unique/cutadapt/unclipped_17_unique_output.fastq --too-short-output $sample_folder/17_unique/cutadapt/too_short_17_unique_output.fastq --too-long-output  $sample_folder/17_unique/cutadapt/too_long_17_unique_output.fastq $file

bowtie2 --very-sensitive --norc --met-file $sample_folder/17_unique/alignment/met_17_unique.txt -p 4 -x $bowtie2_referece_folder -U $sample_folder/17_unique/cutadapt/clipped_17_unique_output.fastq -S $sample_folder/17_unique/alignment/new_17_unique.sam &> $sample_folder/17_unique/alignment/new_17_unique.log

samtools view -F 4 $sample_folder/17_unique/alignment/new_17_unique.sam | cut -f1,3 | sort -k1 > $sample_folder/17_unique/alignment/new_17_unique.txt 2>> $sample_folder/17_unique/alignment/new_17_unique_samtools.log

#barcodes
cutadapt -j 0 -g GTACTGTTGGTAAACCAGCTC -a GGATCCCCAGCTCGCCACCATGGTGTCTAA -O 3 -n 2 -o $sample_folder/barcodes/cutadapt/clipped_barcodes_output.fastq --untrimmed-output $sample_folder/barcodes/cutadapt/unclipped_barcodes_output.fastq --too-short-output $sample_folder/barcodes/cutadapt/too_short_clipped_barcodes_output.fastq --too-long-output $sample_folder/barcodes/too_long_clipped_barcodes_output.fastq $file


python $pyscripts_folder/r1_to_tsv.py $sample_folder/barcodes/cutadapt/clipped_barcodes_output.fastq $sample_folder/barcodes/barcodes_mapping.tsv
python $pyscripts_folder/pair_barcodes_to_unique_17.py $sample_folder/17_unique/alignment/new_17_unique.txt $sample_folder/barcodes/barcodes_mapping.tsv $sample_folder/paired.csv
python $pyscripts_folder/extract_distinct_pairing_and_number_of_barcodes_per_unique_17.py $sample_folder/paired.csv $sample_folder/distinct_paired.csv $sample_folder/number_of_BC_per_unique_17.csv
