#!/bin/bash

# Input arguments
GWAS_DIR="/mnt/project/genuity_data/tmp2_gwas_data"

for gwas_file in "${GWAS_DIR}"/*.regenie*.gz; do

# Extract filename without extension
gwas_name_prefix=$(basename "$gwas_file" .regenie*.gz)

# Check the number of columns in the GWAS file
column_count=$(zcat ${gwas_file} | awk 'NR==1 {print NF}')

# Set the column indices based on the number of columns
if [ "$column_count" -eq 14 ]; then
  beta_col=10
  se_col=11
  log10p_col=13
elif [ "$column_count" -eq 13 ]; then
  beta_col=8
  se_col=9
  log10p_col=11
elif [ "$column_count" -eq 12 ]; then
  beta_col=8
  se_col=9
  log10p_col=11
else
  echo "Unexpected number of columns ($column_count) in ${gwas_file}"
  exit 1
fi

# Create input file for SPrediXcan
echo -e "rsid\tCHROM\tALLELE0\tALLELE1\tBETA\tZ\tP" > ${gwas_name_prefix}.input.txt
zcat ${gwas_file} | awk -v beta_col=$beta_col -v se_col=$se_col -v log10p_col=$log10p_col 'NR>1 {rsid="chr"$1"_"$2"_"$4"_"$5"_b38"; Z=$beta_col/$se_col; print rsid"\t"$1"\t"$4"\t"$5"\t"$beta_col"\t"Z"\t"10^(-$log10p_col)}' >> ${gwas_name_prefix}.input.txt
gzip ${gwas_name_prefix}.input.txt

dx upload ${gwas_name_prefix}.input.txt.gz --destination project-Gv45qjQ09Vk2p6X7q5xJ42PV:/genuity_data/tmp_gwas_data/
done
