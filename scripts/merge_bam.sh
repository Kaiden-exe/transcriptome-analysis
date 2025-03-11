#!/bin/bash
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025
module load samtools/1.21

# Config file 
source $1

allSpecies=($(cut -f4 $manifest | sort | uniq))

start=$EPOCHREALTIME
for speciesID in ${allSpecies[@]}; do
    samtools merge -o $alignmentDir/${speciesID}_merged.bam -@ 7 $alignmentDir/$speciesID/*.sortedByCoord.out.bam
done

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Merging BAM files lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"

sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
