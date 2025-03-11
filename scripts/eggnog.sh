#!/bin/bash
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025
module load eggnog-mapper/2.1.12

# Config file
source $1

# Get protein file
allSpecies=($(cut -f4 $manifest | sort | uniq))
species=${allSpecies[$SLURM_ARRAY_TASK_ID]}
pepFile=$transdecoderOut/$species/${species}.Trinity-GG.fasta.transdecoder.pep

mkdir -p $eggnogOut/$species

start=$EPOCHREALTIME
emapper.py -i $pepFile --itype proteins -o ./$eggnogOut/$species/$species --cpu 24 --data_dir $DAT --sensmode ultra-sensitive --override

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Annotation of $species lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"
echo "DONE"

sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
