#!/bin/bash

# Input arguments
cell_db=$1
gwas_file=$2
cell_covariance=$3
#output_dir=$4

# Extract filename without extension
cell_name_prefix=$(basename "$cell_db" .db)
gwas_name_prefix=$(basename "$gwas_file")

# Start time
start_time=$(date +%s)

# Run SPrediXcan
python /app/MetaXcan/software/SPrediXcan.py \
  --model_db_path ${cell_db} \
  --covariance ${cell_covariance} \
  --gwas_file ${gwas_file} \
  --snp_column SNPID \
  --effect_allele_column ALLELE1 \
  --non_effect_allele_column ALLELE0 \
  --beta_column BETA \
  --se_column SE \
  --zscore_column ZSCORE \
  --keep_non_rsid \
  --pvalue_column PVALUE \
  --output_file ${gwas_name_prefix}.predixcan_${cell_name_prefix}.csv

# Upload result to DNAnexus
#dx upload ${output_dir}/${gwas_name_prefix}.predixcan_${cell_name_prefix}.csv --destination ${output_dir}/

# End time
end_time=$(date +%s)
runtime=$((end_time - start_time))
echo "Processing time for ${gwas_name_prefix}.predixcan_${cell_name_prefix}: ${runtime} seconds"
