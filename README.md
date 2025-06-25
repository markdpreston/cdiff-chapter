# From FASTQ to Function to Phylogeny: in silico methods for antimicrobial resistance and outbreak investigation
This repository contains supplementary materials for the chapter of _[THE BOOK]_: _"From FASTQ to Function to Phylogeny: in silico methods for antimicrobial resistance and outbreak investigation"_.

This repository includes:

- **Scripts** for running the described methods
- **Text files** that contains information of bioinforamtics softwares used and information of isolates used in the chapter
- **Example output** that not included in the print version

## Requirements & Installation
We assume that you have access to a Linux system, either directly via a Linux computer, using the Terminal App on a Mac, or via the Windows Subsystem for Linux (WSL) on a Windows computer.
### Install non-bioinformatic tools
```bash
sudo apt-get update 
sudo apt-get install git sed unzip wget 
```
### Clone this repository
```bash
git clone https://github.com/markdpreston/cdiff-chapter.git
```
### Install bioinformatic tools using `conda`
1. Download and install `Miniconda`
```bash
# Assuming your machine is Linux x86_64.
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```
2. Agree to the license, install location and initialisation of `conda`.
3. Close and reopen terminal for `conada` activation.
4. Configure `conda` with required channels.
```bash
conda config --add channels bioconda
conda config --add channels conda-forge
```
5. Install required bioinformatic tools. They will be installed in an environment called `cdiff`.
```bash
conda env create --file <git_repo_folder>/environment.yaml
```
6. Activate the `cdiff` environment.
```bash
conda activate cdiff
```

## Usage
### Download genome references:
```bash
bash download_reference.sh <reference_folder>
```
### Download data:
To download the example data ("sample1", i.e. SRR12437196) in the chapter:
```bash
bash download_data.sh <data_folder>
```
If you would like download multiple data, specify the text file that contains the SRR numbers per row with `--multi` option:
```bash
bash download_data.sh <data_folder> --multi <ssr_number.txt>
```
### Run bioinformatic pipeline:
```bash
bash main.sh <data_folder> <reference_folder> <working_folder> [threads]
```
`working_folder` is the destination of all the output files from the pipeline. Output files include:

- Default outputs from the bioinformatic tools
- Result summary TSVs of `fastp` and `quast` for all samples processed

Number of thread is 1 by default.

## Metadata files
The two metadata text files used to generate GrapeTree and PHYLOViZ Online screenshots in the chapter.

## Example output files
We have also uploaded two `FastTree` output files (`Snippy` and `roary`) and the `ChewBBACA` profile data to the folder `example_output` in this repository.
