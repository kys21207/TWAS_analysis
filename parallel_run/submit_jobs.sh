#!/bin/bash

echo "HERE"

# Directories
PROJECT="project-Gv45qjQ09Vk2p6X7q5xJ42PV"
GWAS_DIR="/mnt/project/genuity_data/time2event_results"
CELL_DIR="/mnt/project/publically_available_supporting_files/scPrediXcan/immune_model"
OUTPUT_DIR="project-Gv45qjQ09Vk2p6X7q5xJ42PV:/analysis_KJ/scPrediXcan/"
IMAGE_FILE="project-GB8P46j0BkYky47b1ZP4bqKp:/docker_images/predixcan_v20250204.tar.gz"

MAX_JOBS=1  # Maximum number of simultaneous jobs

submit_job() {
  local cell=$1
  local file=$2

  # Upload files to DNAnexus
  cell_db_id=${PROJECT}:/${cell#/mnt/project/}
  gwas_file_id=${PROJECT}:/${file#/mnt/project/}
  cell_covariance_id=${PROJECT}:/${CELL_DIR#/mnt/project/}/$(basename "$cell" .db)_covariances.txt.gz

  dx run swiss-army-knife \
    -iimage_file=${IMAGE_FILE} \
    -iin=${gwas_file_id} \
    -iin=${cell_db_id} \
    -iin=${cell_covariance_id} \
    --destination ${OUTPUT_DIR} \
    --instance-type "mem3_ssd1_v2_x4" \
    --delay-workspace-destruction \
    --priority high \
    --yes \
    --brief \
    -icmd="bash process_gwas.sh ${cell_db_id} ${gwas_file_id} ${cell_covariance_id}"
}

counter=0
job_count=0

for cell in "$CELL_DIR"/*.db; do
  # Skip if no files are found
  [ -e "$cell" ] || continue
  # Increment counter
  counter=$((counter + 1))
  # Skip the first file
  if [ $counter -le 1 ]; then
    continue
  fi

  for file in "$GWAS_DIR"/*.regenie*.gz; do
    # Skip if no files are found
    [ -e "$file" ] || continue
    echo "$cell & $file"
    # Submit the job
    submit_job "$cell" "$file"
    job_count=$((job_count + 1))

    # Check if we have reached the maximum number of simultaneous jobs
    if [ $job_count -ge $MAX_JOBS ]; then
      echo "Waiting for some jobs to complete..."
      while [ $(dx find jobs --state running --brief | wc -l) -ge $MAX_JOBS ]; do
        sleep 60  # Wait for a minute before checking again
      done
      job_count=0  # Reset the job count after some jobs have completed
    fi
  done
done

for cell in "$CELL_DIR"/*.db; do
 echo "$cell"
done
