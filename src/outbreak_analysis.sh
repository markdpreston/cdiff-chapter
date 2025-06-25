#!/bin/bash
# Functions to run outbreak analysis

prepare_snippy_input() {
  local sample_list="$1"
  log 'Prepare Snippy input tab file'
  # remove existing one to keep it only for current pipeline run
  if [ -f "${WORK_DIR}/snippy_input.tab" ]; then rm "${WORK_DIR}/snippy_input.tab"; fi
  touch "${WORK_DIR}/snippy_input.tab"
  for sample in $sample_list; do
    echo -e "${sample}\t${WORK_DIR}/fastp/${sample}.p1.fastq.gz\t${WORK_DIR}/fastp/${sample}.p2.fastq.gz" \
      >> "${WORK_DIR}/snippy_input.tab"
  done
}

run_snippy() {
  log 'Snippy'
  mkdir -p "${WORK_DIR}/snippy"
  current_dir="$(pwd)"
  echo "$current_dir"
  cd "${WORK_DIR}/snippy" || exit
  snippy-multi "${WORK_DIR}/snippy_input.tab" --cpus "$THREADS" --ref "${REF_DIR}/R20291.embl" \
    > "${WORK_DIR}/snippy/runme.sh"
  sh "${WORK_DIR}/snippy/runme.sh"
  cd "$current_dir" || exit
}

combine_snps_txt() {
  local sample_list="$1"

  log 'Combine snps.txt from snippy for samples'
  # The header line of TSV
  echo -e "Sample\tVariant-COMPLEX\tVariant-DEL\tVariant-INS\tVariant-MNP\tVariant-SNP\tVariantTotal" \
    > "${WORK_DIR}/snippy/snippy_snp_summary.tsv"

  for sample in $sample_list; do
    complex=0; del=0; ins=0; mnp=0; snp=0; total=0
    while read -r variant count; do
      case "$variant" in
        "Variant-COMPLEX") complex=$count ;;
        "Variant-DEL") del=$count ;;
        "Variant-INS") ins=$count ;;
        "Variant-MNP") mnp=$count ;;
        "Variant-SNP") snp=$count ;;
        "VariantTotal") total=$count ;;
      esac
    done < <(tail -n +6 "${WORK_DIR}/snippy/${sample}/snps.txt")
    # Print result to TSV
    echo -e "$sample\t$complex\t$del\t$ins\t$mnp\t$snp\t$total" \
      >> "${WORK_DIR}/snippy/snippy_snp_summary.tsv"
  done
}

run_snippy_fasttree() {
  # Process snippy-multi output to get FastTree
  log 'Gubbins and FastTree for Snippy results'
  snippy-clean_full_aln "${WORK_DIR}/snippy/core.full.aln" >"${WORK_DIR}/snippy/clean.full.aln"
  run_gubbins.py -c "$THREADS" -p "${WORK_DIR}/snippy/gubbins" "${WORK_DIR}/snippy/clean.full.aln"
  snp-sites -c "${WORK_DIR}/snippy/gubbins.filtered_polymorphic_sites.fasta" \
    > "${WORK_DIR}/snippy/clean.core.aln"
  FastTree -gtr -nt "${WORK_DIR}/snippy/clean.core.aln" > "${WORK_DIR}/snippy/clean.core.tree"
}

run_abricate() {
  mapfile -t fasta_files < <(find "${WORK_DIR}/unicycler" -name "assembly_*.fasta")

  # AMR genes - abricate
  log 'abricate'
  mkdir -p "${WORK_DIR}/abricate"
  abricate -db card --mincov 95 "${fasta_files[@]}" > "${WORK_DIR}/abricate/results_card.tab"
  abricate --summary "${WORK_DIR}/abricate/results_card.tab" > "${WORK_DIR}/abricate/summary_card.tab"

  ## Make abbricate result tables pretty - keep only SRR number from the filename
  # shellcheck disable=2002
  cat "${WORK_DIR}/abricate/summary_card.tab" |\
    sed -e "s|${WORK_DIR}/unicycler/assembly_||g;s/.fasta//g" \
    > "${WORK_DIR}/abricate/summary_card_pretty.tab"
  # shellcheck disable=2002
  cat "${WORK_DIR}/abricate/results_card.tab" |\
    sed -e "s|${WORK_DIR}/unicycler/assembly_||g;s/.fasta//g" \
    > "${WORK_DIR}/abricate/results_card_pretty.tab"
}

run_roary() {
  mapfile -t gff_files < <(find "${WORK_DIR}/prokka" -name "*.gff")
  log 'Roary'
  rm -rf "${WORK_DIR}/roary"  # roary will create "roary_xxx" if folder exist
  roary -e --mafft -p "$THREADS" -f "${WORK_DIR}/roary" -v "${gff_files[@]}"
  FastTree -gtr -nt -gamma "${WORK_DIR}/roary/core_gene_alignment.aln" \
    > "${WORK_DIR}/roary/core_gene.tree"
}

run_chewbbaca() {
  mapfile -t fna_files < <(find "${WORK_DIR}/prokka" -name "*.fna")
  log 'chewbbaca'
  mkdir -p "${WORK_DIR}/chewbbaca/fasta"
  eval rm -rf "${WORK_DIR}/chewbbaca/results_*"

  # Copy files into fasta folder, since -i option take only one argument at a time.
  cp "${fna_files[@]}" "${WORK_DIR}/chewbbaca/fasta"

  chewBBACA.py AlleleCall --cpu "$THREADS" -i "${WORK_DIR}/chewbbaca/fasta" \
    -g "${REF_DIR}/cb_schema" -o "${WORK_DIR}/chewbbaca"
}
