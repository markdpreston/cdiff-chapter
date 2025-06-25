#!/bin/bash
# Functions for creating genome from reads and identifying genes
# `run_contigs_assemble`, `run_abacas` and `run_prokka` are for single sample.

run_contigs_assemble() {
  local sample="$1"

  # Assemble - Unicycler
  log 'Unicycler' "$sample"
  mkdir -p "${WORK_DIR}/unicycler/${sample}"  # Unicycler doesn't allow customise file name
  unicycler -1 "${WORK_DIR}/fastp/${sample}.p1.fastq.gz" -2 "${WORK_DIR}/fastp/${sample}.p2.fastq.gz" \
    -o "${WORK_DIR}/unicycler/${sample}" -t "$THREADS" --min_fasta_length 500 \
    &> "${WORK_DIR}/unicycler/${sample}/unicycler.log"

  # Copy file up one folder (Unicycler) and rename assembly.fasta
  cp "${WORK_DIR}/unicycler/${sample}/assembly.fasta" "${WORK_DIR}/unicycler/assembly_${sample}.fasta"

  # QC the assemblies - QUAST
  log 'QUAST' "$sample"
  mkdir -p "${WORK_DIR}/quast"
  quast -o "${WORK_DIR}/quast/${sample}" -t "$THREADS" -r "${REF_DIR}/R20291.fasta" \
    "${WORK_DIR}/unicycler/assembly_${sample}.fasta"
}

combine_quast_results() {
  log 'Combine quast results'
  mapfile -t quast_results < <(find "${WORK_DIR}/quast" -name report.tsv | sort)
  cp "${quast_results[0]}" "${WORK_DIR}/quast/quast_summary.tsv"

  for (( i=1; i<"${#quast_results[@]}"; i++ )); do
    join -t $'\t' "${WORK_DIR}/quast/quast_summary.tsv" "${quast_results[i]}" > "${WORK_DIR}/quast/tmp"
    mv "${WORK_DIR}/quast/tmp" "${WORK_DIR}/quast/quast_summary.tsv"
  done

  sed -i 's/assembly_//g' "${WORK_DIR}/quast/quast_summary.tsv"
}

run_abacas() {
  local sample="$1"
  log 'Abacas - order contigs' "$sample"
  mkdir -p "${WORK_DIR}/abacas/"  # Abcas doesn't allow customise file name
  abacas.1.3.1.pl -r "${REF_DIR}/R20291.fasta" -q "${WORK_DIR}/unicycler/assembly_${sample}.fasta" \
    -p nucmer -c -d -N -a -o "${WORK_DIR}/abacas/${sample}"
}

run_prokka() {
  local sample="$1"
  fasta_file="$(find "${WORK_DIR}/abacas" -name "${sample}.NoNs.fasta")"
  log 'prokka - annotation' "$sample"
  prokka --cpus "$THREADS" --outdir "${WORK_DIR}/prokka" --force --prefix "${sample}" \
    "$fasta_file" --centre X --compliant
}
