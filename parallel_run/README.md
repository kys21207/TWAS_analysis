## 1. create a docker image for spredixcan using Dockerfile
  docker build -t spredixcan:latest . <br>
  docker run --rm -v $(pwd):/data spredixcan:latest --model_db_path /data/model.db --covariance /data/covariance.txt.gz --gwas_file /data/gwas.txt --output_file /data/output.csv
## 2. Able to control # of parallel jobs
