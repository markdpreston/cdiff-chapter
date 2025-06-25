#!/bin/bash
# Download the example data used in the chapter. If `--multi` not specify, the script
# will download the "sample1" in the chapter, i.e. SRR12437196. 

# Check if parameter(s) supplied
if [[ "$#" -lt 1 ]]; then 
  echo "Usage: bash download_data.sh <data directory> [--multi <SRR number.txt>]" \
  && exit 1
fi

# Default value
DATA_DIR=""
MULTI_MODE=false
MULTI_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --multi) MULTI_MODE=true && MULTI_FILE="$2" && shift 2 ;;
    *)       DATA_DIR="$1" && shift                        ;;
  esac
done

# Debug
echo "Data directory: $DATA_DIR"
if [ "$MULTI_MODE" = true ]; then
    echo "Multi-mode enabled"
    echo "Using SRR file: $MULTI_FILE"
fi

# Main
mkdir -p "$DATA_DIR"

if [ "$MULTI_MODE" = false ]; then
  prefetch SRR12437196 --output-directory "$DATA_DIR"
  fasterq-dump --split-files "${DATA_DIR}/SRR12437196/SRR12437196.sra" --outdir "$DATA_DIR" --progress
  gzip -v "${DATA_DIR}/SRR12437196_1.fastq"
  gzip -v "${DATA_DIR}/SRR12437196_2.fastq"
  rm -rf "${DATA_DIR}/SRR12437196"
else
  srr_numbers="$(cat "$MULTI_FILE")"
  for srr in $srr_numbers; do
    echo "Downloading ${srr}"
    prefetch "$srr" --output-directory "$DATA_DIR"
    fasterq-dump --split-files "${DATA_DIR}/${srr}/${srr}.sra" --outdir "$DATA_DIR" --progress
    gzip -v "${DATA_DIR}/${srr}_1.fastq"
    gzip -v "${DATA_DIR}/${srr}_2.fastq"
    folder="${DATA_DIR}/${srr}"
    rm -rf "${folder:?}/"*
  done
fi
