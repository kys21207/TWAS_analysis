# SPrediXcan_run

## download immune cell
From https://zenodo.org/records/14346661 using the below step
All dataset were built using hg38.
### Install the package inborutis and load into library
library(inborutils)

doi <- "10.5281/zenodo.3923633" <br>
local_path <- "data" <br>
inborutils::download_zenodo(doi, local_path, quiet = TRUE) <br>
list.files(local_path)

## Description for a result
- gene: 
a gene's id: as listed in the Tissue Transcriptome model. Ensemble Id for most gene model releases. Can also be a intron's id for splicing model releases.
- gene_name: 
gene name as listed by the Transcriptome Model, typically HUGO for a gene. It can also be an intron's id.
- zscore: 
S-PrediXcan's association result for the gene, typically HUGO for a gene.
- effect_size: 
S-PrediXcan's association effect size for the gene. Can only be computed when beta from the GWAS is used.
- pvalue: 
P-value of the aforementioned statistic.
- pred_perf_r2: 
(cross-validated) R2 of tissue model's correlation to gene's measured transcriptome (prediction performance). Not all model families have this (e.g. MASHR).
- pred_perf_pval: 
pval of tissue model's correlation to gene's measured transcriptome (prediction performance). Not all model families have this (e.g. MASHR).
- pred_perf_qval: 
qval of tissue model's correlation to gene's measured transcriptome (prediction performance). Not all model families have this (e.g. MASHR).
- n_snps_used: 
number of snps from GWAS that got used in S-PrediXcan analysis
- n_snps_in_cov: 
number of snps in the covariance matrix
- n_snps_in_model: 
number of snps in the model
- var_g: 
variance of the gene expression, calculated as W' * G * W (where W is the vector of SNP weights in a gene's model, W' is its transpose, and G is the covariance matrix)
