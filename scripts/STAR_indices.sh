#!/bin/bash
module load star/2.7.11a
echo "$SLURM_ARRAY_TASK_ID"

# Config file
source $1

# Get right file and dir
allSpecies=($(cut -f4 $manifest | sort | uniq))
species=${allSpecies[$SLURM_ARRAY_TASK_ID]}
genomeRef=$(grep "$species" $referenceTSV | cut -f2)
indexDir="$alignmentDir/$(basename "$genomeRef" .fa)_indices"

# Skip if reference already indexed
if [ -d "$indexDir" ] && [ "$(ls $indexDir | wc -l)" -gt 0 ] ; then
    echo "WARNING: REFERENCE $genomeRef SEEMS TO BE ALREADY INDEXED"
    echo "Skipping indexing $genomeRef"
    exit 0
fi

mkdir -p $indexDir
start=$EPOCHREALTIME

STAR --runThreadN 8 --runMode genomeGenerate --genomeDir $indexDir --genomeFastaFiles $genomeRef \
    --limitGenomeGenerateRAM 250000000000 --genomeSAindexNbases 12

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Indexing of reference for $species lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"
echo "DONE"

sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
