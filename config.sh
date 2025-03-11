# Author: Kaiden R. Sewradj
# Last update: 11/03/2025

# Project directory
DIR=~/project


########## STEP 1: ALIGN WITH STAR ##########
# Location of alignment files and indices directories
alignmentDir=alignment

# tsv of ID of the replicate, read files, reference and speciesID (NO header)
# ID    reads1   reads2     speciesID
# e.g. ADRSCO_B5_15_0Gy  ADRSCO_B5_15_0Gy_r1.fastq.gz   ADRSCO_B5_15_0Gy_r2.fastq.gz    Asco
manifest=manifest.tsv

# tsv of speciesID (same as manifest) and reference genome, no header
# e.g. Asco     reference.fasta
referenceTSV=references.tsv

########## STEP 2: CLUSTER INTO GENES WITH TRINITY ##########
trinityOut=trinity_output

########## STEP 3: SALMON EXPRESSION QUANTIFICATION ##########
salmonOut=salmon_output

########## STEP 4: DEG/PCA ANALYSIS ##########
# tsv of ID of the ID, condition, batch (WITH header)
# ID    condition   batch
# e.g. ADRSCO_B5_15_0Gy     0Gy    5
conditions=conditions.tsv
DEGout=DEG_output

########## STEP 5: TRANSLATE TO PROTEOME ##########
transdecoderOut=transdecoder_output

########## STEP 6: ANNOTATE PROTEINS ##########
# Database location for eggnog data
DAT=/databank/eggnog
eggnogOut=eggnog_output
