#!/bin/bash
# Download C. difficile (R20291) reference annotation and chewBBACA schema

if [[ "$#" -lt 1 ]]; then echo "Usage: ./download_references.sh <reference_dir>" && exit 1; fi
REF_DIR="$1"

mkdir -p "$REF_DIR"

# Download reference annotation
wget "https://www.ebi.ac.uk/ena/browser/api/embl/FN545816.1?download=true" -O "${REF_DIR}/R20291.embl"
wget "https://www.ebi.ac.uk/ena/browser/api/fasta/FN545816.1?download=true" -O "${REF_DIR}/R20291.fasta"

# Download chewBBACA schema
# wget "https://www.cgmlst.org/ncs/schema/Cdifficile1760/alleles/" -O "${REF_DIR}/cdiff_cgmlst.zip"
# ** Use local version in the Git provided by Richard
mv "data/cdiff_cgmlst.zip" "${REF_DIR}/cdiff_cgmlst.zip"
unzip "${REF_DIR}/cdiff_cgmlst.zip" -d "${REF_DIR}/cdiff_cgmlst"

# Prepare chewBBACA schema
chewBBACA.py PrepExternalSchema --cpu 4 -i "${REF_DIR}/cdiff_cgmlst" -o "${REF_DIR}/cb_schema"
