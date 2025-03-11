#!/bin/bash
module load salmon/1.10.2
echo "$SLURM_ARRAY_TASK_ID"

# Config file 
source $1

# Get species
allSpecies=($(cut -f4 $manifest | sort | uniq))
species=${allSpecies[$SLURM_ARRAY_TASK_ID]}
outDir=$salmonOut/${species}_indices

# Build indices
mkdir -p $outDir
start=$EPOCHREALTIME
salmon index -t $trinityOut/$species/${species}.Trinity-GG.fasta --keepDuplicates -i $outDir -k 31 -p 4 

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Indexing of $species transcriptome lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"
echo "DONE"
sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
