#!/bin/bash
set -e

echo "Starting job submission process at $(date)"

# Directories
PROJECT="project-Gv45qjQ09Vk2p6X7q5xJ42PV"
GWAS_DIR="/mnt/project/genuity_data/time2event_results"
CELL_DIR="/mnt/project/publically_available_supporting_files/scPrediXcan/immune_model"
OUTPUT_DIR="${PROJECT}:/analysis_KJ/scPrediXcan/"
IMAGE_FILE="project-GB8P46j0BkYky47b1ZP4bqKp:/docker_images/predixcan_v20250204.tar.gz"

MAX_JOBS=1  # Maximum number of simultaneous jobs

submit_job() {
    local cell=$1
    local file=$2
    
    # Convert local paths to DNAnexus paths
    local cell_db="${PROJECT}:/${cell#/mnt/project/}"
    local gwas_file="${PROJECT}:/${file#/mnt/project/}"
    local cell_covariance="${PROJECT}:/${CELL_DIR#/mnt/project/}/$(basename "$cell" .db)_covariances.txt.gz"
    local cell_db_id="$(basename ${cell})"
    local gwas_file_id="$(basename ${file})"
    local cell_covariance_id="$(basename ${cell} .db)_covariances.txt.gz"
    local gwas_name="$(basename ${file} .regenie.gz)"
    local cell_name="$(basename ${cell} .db)"

    echo "Submitting job with:"
    echo "Cell DB: ${cell_db_id}"
    echo "GWAS: ${gwas_file_id}"
    echo "Covariance: ${cell_covariance_id}"

    # Submit the job and capture the job ID
    local job_id=$(dx run swiss-army-knife \
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
        -icmd="python /app/MetaXcan/software/SPrediXcan.py --model_db_path ${cell_db_id} --gwas_file ${gwas_file_id} --snp_column SNPID --beta_column BETA --effect_allele_column ALLELE1 --non_effect_allele_column ALLELE0 --se_column SE --zscore_column ZSCORE --covariance ${cell_covariance_id} --keep_non_rsid --pvalue_column PVALUE --output_file ${gwas_name}.preixcan_${cell_name}_cells.csv"`")
    
    echo "Submitted job ${job_id} at $(date)"
    echo "${job_id}" > current_job_id.txt
}

wait_for_current_job() {
    if [ ! -f current_job_id.txt ]; then
        return 0
    fi

    local job_id=$(cat current_job_id.txt)
    echo "Waiting for job ${job_id} to complete..."
    
    while true; do
        local state=$(dx describe --json "$job_id" | jq -r .state)
        echo "Job ${job_id} state: ${state} at $(date)"
        
        if [ "$state" == "done" ]; then
            echo "Job ${job_id} completed successfully"
            rm current_job_id.txt
            return 0
        elif [ "$state" == "failed" ] || [ "$state" == "terminated" ]; then
            echo "Job ${job_id} failed or was terminated"
            rm current_job_id.txt
            return 1
        fi
        
        sleep 60  # Check every minute
    done
}

counter=0

echo "Scanning for cell files in ${CELL_DIR}"
for cell in "${CELL_DIR}"/*.db; do
    # Skip if no files are found
    [ -e "$cell" ] || continue
    # Increment counter
    counter=$((counter + 1))
    # Skip the first file
    if [ $counter -le 1 ]; then
        continue
    fi

    echo "Processing cell file: $cell"
    for file in "${GWAS_DIR}"/*.regenie*.gz; do
        # Skip if no files are found
        [ -e "$file" ] || continue
        
        echo "Processing GWAS file: $file at $(date)"
        
        # Submit the job
        submit_job "$cell" "$file"
        
        # Wait for the current job to complete
        if ! wait_for_current_job; then
            echo "Previous job failed, continuing with next job..."
            continue
        fi
    done
done

echo "Job submission complete at $(date)"

# Debug: List all cell files
echo "Available cell files:"
for cell in "${CELL_DIR}"/*.db; do
    echo "$cell"
done
