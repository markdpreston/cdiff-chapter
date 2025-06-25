#!/bin/bash
# Functions for quality control: fastqc and fastp
# `run_fastqc_pre`, `run_trimmer` and `run_fastqc_post` are for single sample.

run_fastqc_pre() {
  local sample="$1"
  log 'Fastqc pre-trim' "$sample"
  mkdir -p "${WORK_DIR}/fastqc_pre"
  data_files="$(find "$DATA_DIR" -name "${sample}*.fastq.gz")"
  for file in $data_files; do
    fastqc -t "$THREADS" "$file" -o "${WORK_DIR}/fastqc_pre"
  done
}

run_trimmer() {
  local sample="$1"
  log 'Fastp' "$sample"
  mkdir -p "${WORK_DIR}/fastp"
  fastp -i "${DATA_DIR}/${sample}_1.fastq.gz" -I "${DATA_DIR}/${sample}_2.fastq.gz" \
        -o "${WORK_DIR}/fastp/${sample}.p1.fastq.gz" -O "${WORK_DIR}/fastp/${sample}.p2.fastq.gz" \
        --unpaired1 "${WORK_DIR}/fastp/${sample}.s1.fastq.gz" --unpaired2 "${WORK_DIR}/fastp/${sample}.s2.fastq.gz" \
        --cut_right --cut_window_size 4 --cut_mean_quality 20 --length_required 50 \
        --thread "$THREADS" \
        --html "${WORK_DIR}/fastp/fastp_${sample}.html" --json "${WORK_DIR}/fastp/fastp_${sample}.json" \
        &> "${WORK_DIR}/fastp/fastp_${sample}.log"

  ## Extract summary from fastp.log and make it tab-separated
  head -n 35 "${WORK_DIR}/fastp/fastp_${sample}.log" | sed "s/: /\t/g" \
    > "${WORK_DIR}/fastp/fastp_log_${sample}.tsv"
}

run_fastqc_post() {
  # Fastqc post-trim
  log 'Fastqc post-trim'
  mkdir -p "${WORK_DIR}/fastqc_post"
  fp_files="$(find "${WORK_DIR}/fastp" -name "*.fastq.gz")"
  for file in $fp_files; do
    fastqc -t "$THREADS" "$file" -o "${WORK_DIR}/fastqc_post/"
  done
}

combine_fastp_log() {
  log 'Combine fastp log'
  mapfile -t fastp_logs < <(find "${WORK_DIR}/fastp" -name "fastp_log_*.tsv" | sort)
  # fastp_logs=($(find "${WORK_DIR}/fastp" -name "fastp_log_*.tsv" | sort))

  ## Extract first column
  cut -f 1 "${fastp_logs[0]}" > "${WORK_DIR}/fastp/fastp_summary.tsv"
  sed -i '1s/^/SAMPLE\n/' "${WORK_DIR}/fastp/fastp_summary.tsv"

  ## Extract second column for all fastp_logs
  for (( i=0; i<"${#fastp_logs[@]}"; i++ )); do
    sample_name="$(echo "${fastp_logs[i]}" | sed "s|${WORK_DIR}/fastp/fastp_log_||g" | sed "s/.tsv//g")"
    # To keep redability of the cat, sed and cut line:
    # shellcheck disable=2002
    cat "${fastp_logs[i]}" | sed 's/^.*://' | cut -f 2 > "${WORK_DIR}/fastp/tmp.tsv"
    sed -i "1s/^/${sample_name}\n/" "${WORK_DIR}/fastp/tmp.tsv"
    paste -d '\t' "${WORK_DIR}/fastp/fastp_summary.tsv" "${WORK_DIR}/fastp/tmp.tsv" \
      > "${WORK_DIR}/fastp/tmp_summary.tsv"
    mv "${WORK_DIR}/fastp/tmp_summary.tsv" "${WORK_DIR}/fastp/fastp_summary.tsv"
  done
  rm -f "${WORK_DIR}/fastp/tmp.tsv"
}
