#!/bin/bash
module load salmon/1.10.2
echo "$SLURM_ARRAY_TASK_ID"

# Config file
source $1

# Get read files and dirs
LINE=$(sed -n "$SLURM_ARRAY_TASK_ID"p "$manifest")
ID=$(echo "$LINE" | cut -f1)
read1=$(echo "$LINE" | cut -f2)
read2=$(echo "$LINE" | cut -f3)
species=$(echo "$LINE" | cut -f4)
indexDir=$salmonOut/${species}_indices
outDir=$salmonOut/$ID

start=$EPOCHREALTIME
if [ -z "${read2}" ] ; then 
    salmon quant -i $indexDir -l ISR -r $read1 -o $outDir -p 12 --validateMappings
else
    salmon quant -i $indexDir -l ISR -1 $read1 -2 $read2 -o $outDir -p 12 --validateMappings
fi

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Quantification of $species lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"
echo "DONE"

sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
