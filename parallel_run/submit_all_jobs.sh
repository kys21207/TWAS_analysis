#!/bin/bash

# Directories
PROJECT="project-Gv45qjQ09Vk2p6X7q5xJ42PV"
GWAS_FILE="/mnt/project/genuity_data/tmp3_gwas_data/psoriasis_harm_input.txt.gz"
CELL_DIR="/mnt/project/publically_available_supporting_files/scPrediXcan/bulk_tissues"
OUTPUT_DIR="${PROJECT}:/analysis_KJ/scPrediXcan/results/"
IMAGE_FILE="project-GB8P46j0BkYky47b1ZP4bqKp:/docker_images/predixcan_v20250204.tar.gz"

# Function to check if the project exists
check_project() {
    local project_id=$1
    if ! dx describe "$project_id" &> /dev/null; then
        echo "Error: Could not find a project named \"$project_id\""
        exit 1
    fi
}

submit_job() {
    local cell=$1
    local file=$2
    
    # Convert local paths to DNAnexus paths
    local cell_db="${PROJECT}:/${cell#/mnt/project/}"
    local gwas_file="${PROJECT}:/${file#/mnt/project/}"
    local cell_covariance="${PROJECT}:/${CELL_DIR#/mnt/project/}/$(basename "$cell" .db).txt.gz"
    local cell_db_id="$(basename ${cell})"
    local gwas_file_id="$(basename ${file})"
    local cell_covariance_id="$(basename ${cell} .db).txt.gz"
    local gwas_name="$(basename ${file} .txt.gz)"
    local cell_name="$(basename ${cell} .db)"

    echo "Submitting job with:"
    echo "Cell DB: ${cell_db_id}"
    echo "GWAS: ${gwas_file_id}"
    echo "Covariance: ${cell_covariance_id}"

    # Submit the job and capture the job ID
    dx run swiss-army-knife \
        -iimage_file="${IMAGE_FILE}" \
        -iin="${gwas_file}" \
        -iin="${cell_db}" \
        -iin="${cell_covariance}" \
        --destination "${OUTPUT_DIR}" \
        --instance-type "mem3_ssd1_v2_x4" \
        --delay-workspace-destruction \
        --priority high \
        --yes \
        --brief \
        -icmd="python /app/MetaXcan/software/SPrediXcan.py --model_db_path ${cell_db_id} --gwas_file ${gwas_file_id} --snp_column rsid --beta_column beta --effect_allele_column effect_allele --non_effect_allele_column other_allele --se_column standard_error --covariance ${cell_covariance_id} --keep_non_rsid --pvalue_column p_value --gwas_N 426000 --gwas_h2 0.23 --output_file ${gwas_name}.preixcan_${cell_name}_tissue.csv"
}

# Check if the project exists
check_project "$PROJECT"

echo "Scanning for cell files in ${CELL_DIR}"
for cell in "${CELL_DIR}"/*.db; do
    
    echo "Processing cell file: $cell"
#    for file in "${GWAS_DIR}"/*.input.txt.gz; do
        
        # Submit the job
        submit_job "$cell" "$GWAS_FILE"
#     done
done
