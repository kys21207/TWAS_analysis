#!/bin/bash 

# Check if an argument was provided
#if [ $# -eq 0 ]; then
#    echo "No arguments supplied. Please provide a directory and a file name for a CELL summary statistic."
#    echo "Usage: $0 CELL_SUM_file_name"
#    exit 1
#fi

#cell_name=$1
#cell_name="CD4-positive_alpha-beta_cytotoxic_T_cell"

mkdir -p /opt/notebooks/data/
mkdir -p /opt/notebooks/results/

# c("CHROM", "GENPOS", "SNPID", "ALLELE0", "ALLELE1", "A1FREQ", "INFO", "N", "TEST", "BETA", "SE", "CHISQ", "LOG10P", "EXTRA")
#gwas_name_prefix="ms_all_comers_age_onset"
GWAS_DIR="/mnt/project/genuity_data/time2event_results"
CELL_DIR="/mnt/project/publically_available_supporting_files/scPrediXcan/immune_model"

counter=0

for cell in "$CELL_DIR"/*.db; do
#skip if no files are found
   [ -e "$file" ] || continue
   # Increment counter
      counter=$((counter + 1))
   # Skip the first file
      if [ $counter -le 1 ]; then
         continue
      fi
 
 #extract filename without extention
  cell_name_prefix=$(basename "$cell" .db)


for file in "$GWAS_DIR"/*.regenie.gz; do
   #skip if no files are found
   [ -e "$file" ] || continue
   #extract filename without extention
   gwas_name_prefix=$(basename "$file" .regenie.gz)

start_time=$(date +%s)

#echo -e "rsid\tCHROM\tALLELE0\tALLELE1\tBETA\tZ\tP" > ./data/${gwas_name_prefix}.input.txt
#zcat ${GWAS_DIR}/${gwas_name_prefix}.regenie.gz | awk 'NR>1 {rsid="chr"$1"_"$2"_"$4"_"$5"_b38"; Z=$10/$11; print #rsid"\t"$1"\t"$4"\t"$5"\t"$10"\t"Z"\t"10^(-$13)}' >> ./data/${gwas_name_prefix}.input.txt
#gzip ./data/${gwas_name_prefix}.input.txt

/opt/notebooks/MetaXcan/software/SPrediXcan.py \
--model_db_path ${CELL_DIR}/${cell_name_prefix}.db \
--covariance ${CELL_DIR}/${cell_name_prefix}_covariances.txt.gz \
--gwas_folder  /opt/notebooks/data/ \
--gwas_file_pattern "${gwas_name_prefix}.input.txt.gz" \
--snp_column rsid \
--effect_allele_column ALLELE1 \
--non_effect_allele_column ALLELE0 \
--zscore_column Z \
--pvalue_column P \
--beta_column BETA \
--keep_non_rsid \
--output_file /opt/notebooks/results/${gwas_name_prefix}_vs_${cell_name_prefix}.csv

dx upload /opt/notebooks/results/${gwas_name_prefix}_vs_${cell_name_prefix}.csv --destination --destination project-Gv45qjQ09Vk2p6X7q5xJ42PV:/analysis_KJ/scPrediXcan/


   end_time=$(date +%s)
   runtime=$((end_time - start_time))
   echo "Processing time for ${gwas_name_prefix}_vs_${cell_name_prefix}: ${runtime} seconds"

done

done
