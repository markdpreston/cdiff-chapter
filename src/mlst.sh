#!/bin/bash
# Function to run MLST


run_mlst() {
  mapfile -t fasta_files < <(find "${WORK_DIR}/abacas" -name "*.fasta" | grep -v "NoNs")
  log 'MLST'
  mkdir -p "${WORK_DIR}/mlst"
  mlst --legacy --nopath --threads "$THREADS" --scheme cdifficile \
    "${REF_DIR}/R20291.fasta" "${fasta_files[@]}" > "${WORK_DIR}/mlst/mlst.tsv"
}
