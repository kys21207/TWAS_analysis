#!/bin/bash
set -e

echo "Starting job submission process at $(date)"

# Directories
PROJECT="project-Gv45qjQ09Vk2p6X7q5xJ42PV"
GWAS_DIR="/mnt/project/genuity_data/tmp_gwas_data"
CELL_DIR="/mnt/project/publically_available_supporting_files/scPrediXcan/immune_model"
OUTPUT_DIR="${PROJECT}:/analysis_KJ/scPrediXcan/"
IMAGE_FILE="project-GB8P46j0BkYky47b1ZP4bqKp:/docker_images/predixcan_v20250204.tar.gz"

MAX_JOBS=10  # Maximum number of simultaneous jobs

# Array to store running job IDs
declare -a running_jobs=()
total_submitted=0
total_completed=0
total_failed=0

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
    local gwas_name="$(basename ${file} .input.txt.gz)"
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
        -icmd="python /app/MetaXcan/software/SPrediXcan.py --model_db_path ${cell_db_id} --gwas_file ${gwas_file_id} --snp_column rsid --beta_column BETA --effect_allele_column ALLELE1 --non_effect_allele_column ALLELE0 --zscore_column Z --covariance ${cell_covariance_id} --keep_non_rsid --pvalue_column P --output_file ${gwas_name}.preixcan_${cell_name}_cells.csv")
    
    if [ -n "$job_id" ]; then
        echo "Submitted job ${job_id} at $(date)"
        running_jobs+=("$job_id")
        ((total_submitted++))
        echo "Total jobs submitted: $total_submitted"
        return 0
    else
        echo "Failed to submit job at $(date)"
        return 1
    fi
}

check_jobs() {
    local new_running_jobs=()
    local completed=0
    local failed=0
    
    for job_id in "${running_jobs[@]}"; do
        if [ -z "$job_id" ]; then
            continue
        fi
        
        local state=$(dx describe --json "$job_id" | jq -r .state)
        
        case "$state" in
            "done")
                echo "Job ${job_id} completed successfully at $(date)"
                ((completed++))
                ((total_completed++))
                ;;
            "failed"|"terminated")
                echo "Job ${job_id} ${state} at $(date)"
                ((failed++))
                ((total_failed++))
                ;;
            *)
                new_running_jobs+=("$job_id")
                ;;
        esac
    done
    
    running_jobs=("${new_running_jobs[@]}")
    echo "Status: Running: ${#running_jobs[@]}, Completed: $total_completed, Failed: $total_failed, Total Submitted: $total_submitted"
}

wait_for_job_slot() {
    while [ ${#running_jobs[@]} -ge $MAX_JOBS ]; do
        echo "Currently running ${#running_jobs[@]}/$MAX_JOBS jobs, waiting for slot..."
        sleep 30
        check_jobs
    done
}

# Count total expected jobs
total_cells=$(ls "${CELL_DIR}"/*.db 2>/dev/null | wc -l)
total_gwas=$(ls "${GWAS_DIR}"/*.input.txt.gz 2>/dev/null | wc -l)
total_expected=$((total_cells * total_gwas))
echo "Expected total jobs: $total_expected"

echo "Scanning for cell files in ${CELL_DIR}"
for cell in "${CELL_DIR}"/*.db; do
    [ -e "$cell" ] || continue
    
    echo "Processing cell file: $cell"
    for file in "${GWAS_DIR}"/*.input.txt.gz; do
        [ -e "$file" ] || continue
        
        echo "Processing GWAS file: $file at $(date)"
        
        # Wait for available job slot
        wait_for_job_slot
        
        # Submit the job
        if submit_job "$cell" "$file"; then
            # Check jobs status every 3 submissions
            if [ $((total_submitted % 3)) -eq 0 ]; then
                check_jobs
            fi
        else
            echo "Failed to submit job for $file with $cell"
        fi
        
        # Small delay between submissions
        sleep 2
    done
done

# Wait for all remaining jobs to complete
echo "Waiting for remaining jobs to complete..."
while [ ${#running_jobs[@]} -gt 0 ]; do
    sleep 30
    check_jobs
done

echo "Job submission complete at $(date)"
echo "Final Status:"
echo "Total Jobs Submitted: $total_submitted"
echo "Total Jobs Completed: $total_completed"
echo "Total Jobs Failed: $total_failed"
echo "Expected Jobs: $total_expected"
