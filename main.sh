#!/bin/bash
# Main script to run the pipeline.
# It will process all the .fastq.gz file stored in data folder specified.
# Default thread number: 1

if [[ "$#" -lt 3 ]]; then
  echo "Usage: bash main.sh <data_folder> <reference_folder> <working_folder> [threads]" \
  && exit 1
fi
DATA_DIR="${1%/}"
# shellcheck disable=SC2034
REF_DIR="${2%/}"
WORK_DIR="${3%/}"
# shellcheck disable=SC2034
THREADS="${4:-1}"

# Sourcing fuctions to run the bioinformatics tools
source src/utility.sh
source src/quality_control.sh
source src/contigs_assembly_order.sh
source src/mlst.sh
source src/outbreak_analysis.sh

#####
# MAIN
#####
mkdir -p "$WORK_DIR"
# Get the list of sample in the DATA_DIR
r1_list="$(find "$DATA_DIR" -name "*_1.fastq.gz")"
sample_list="$(echo "$r1_list" | sed -E "s|${DATA_DIR}/||" | sed 's/_1.fastq.gz//')"
log "Processing samples:\n${sample_list}\n ------------------------"

# Quality control
for sample in $sample_list; do
  run_fastqc_pre "$sample"
  run_trimmer "$sample"
done
run_fastqc_post
combine_fastp_log

# Contigs assembly, ordering and annotation
for sample in $sample_list; do
  run_contigs_assemble "$sample"
  run_abacas "$sample"
  run_prokka "$sample"
done
combine_quast_results

# MLST
run_mlst

# Outbreak analysis
## Snippy
prepare_snippy_input "${sample_list[@]}"
run_snippy
run_snippy_fasttree
combine_snps_txt "${sample_list[@]}"

## Abricate
run_abricate

## Roary
run_roary

## ChewBBACA
run_chewbbaca
