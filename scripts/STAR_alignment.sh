#!/bin/bash
module load star/2.7.11a
echo "$SLURM_ARRAY_TASK_ID"

# Config file
source $1

# Get read files and dirs
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p "$manifest")
ID=$(echo "$LINE" | cut -f1)
read1=$(echo "$LINE" | cut -f2)
read2=$(echo "$LINE" | cut -f3)
species=$(echo "$LINE" | cut -f4)
genomeRef=$(grep "^$species" $referenceTSV | cut -f2)
indexDir="$alignmentDir/$(basename "$genomeRef" .fa)_indices"

start=$EPOCHREALTIME
STAR --runThreadN 16 --genomeDir $indexDir --readFilesIn $read1 $read2 --readFilesCommand zcat \
    --outFileNamePrefix ${alignmentDir}/${species}/${ID} --outSAMtype BAM SortedByCoordinate --outSAMstrandField intronMotif

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Alignment of $ID lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"    
echo "DONE"

sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
