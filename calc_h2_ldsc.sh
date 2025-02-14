#!/bin/bash

# Define the file paths
gwas_file="/mnt/project/genuity_data/tmp_gwas_data/dx_uc_v3.input.txt.gz"
index_file="/opt/notebooks/convert_spredixcanID_to_ldscID_data.txt.gz"
output_file="/opt/notebooks/dx_uc_v3.txt.gz"

# Perform the merge operation directly on gzipped files
(
    # Print header
    echo -e "CHROM\tALLELE0\tALLELE1\tBETA\tZ\tP\tdbSNP_rsid"
    
    # Join and format the data
    zcat "$index_file" | \
    awk 'NR==FNR{a[$1]=$2; next} $1 in a{print $2, $3, $4, $5, $6, $7, a[$1]}' OFS="\t" - \
    <(zcat "$gwas_file") 
) | gzip > "$output_file"


./munge_sumstats.py \
--out /opt/notebooks/dx_uc_v3 \
--p P \
--a1 ALLELE1 \
--a2 ALLELE0 \
--signed-sumstats Z,0 \
--N 14012 \
--snp dbSNP_rsid \
--sumstats ${output_file} 

cp -r /mnt/project/publically_available_supporting_files/GRCh38/ /opt/notebooks/
tar -xvzf /opt/notebooks/GRCh38/baselineLD_v2.2.tgz
tar -xvzf /opt/notebooks/GRCh38/weights.tgz 

ldsc.py \
--h2 /opt/notebooks/dx_uc_v3.sumstats.gz \
--ref-ld-chr baselineLD_v2.2/baselineLD.@ \
--w-ld-chr weights/weights.hm3_noMHC.@ \
--out /opt/notebooks/dx_uc_v3


./munge_sumstats.py \
--out /opt/notebooks/psoriasis_harm \
--p p_value \
--a1 effect_allele \
--a2 other_allele  \
--N 426000 \
--snp rsid \
--sumstats /mnt/project/publically_available_supporting_files/gwas_public_results/autoimmune_step_2_additive_psoriasis_harm_input.h.tsv.gz  

cp -r /mnt/project/publically_available_supporting_files/GRCh38/ /opt/notebooks/
tar -xvzf /opt/notebooks/GRCh38/baselineLD_v2.2.tgz
tar -xvzf /opt/notebooks/GRCh38/weights.tgz 

./ldsc.py \
--h2 /opt/notebooks/psoriasis_harm.sumstats.gz \
--ref-ld-chr /opt/notebooks/baselineLD_v2.2/baselineLD.@ \
--w-ld-chr /opt/notebooks/weights/weights.hm3_noMHC.@ \
--samp-prev 0.014 \
--pop-prev 0.02 \
--out /opt/notebooks/psoriasis_harm
