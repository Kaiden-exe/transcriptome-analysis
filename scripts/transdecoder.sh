#!/bin/bash
module load singularity
echo "$SLURM_ARRAY_TASK_ID"

# Config file
source $1

# Get right files and dirs
allSpecies=($(cut -f4 $manifest | sort | uniq))
species=${allSpecies[$SLURM_ARRAY_TASK_ID]}
outDir=${transdecoderOut}/${species}
mkdir -p $outDir
trinAssem=$trinityOut/$species/${species}.Trinity-GG.fasta
trinMap=${trinAssem}.gene_trans_map

start=$EPOCHREALTIME
singularity exec --bind $DIR $DIR/bin/transdecoder_5.7.1.sif TransDecoder.LongOrfs -t $trinAssem --gene_trans_map $trinMap -O $outDir
singularity exec --bind $DIR $DIR/bin/transdecoder_5.7.1.sif TransDecoder.Predict -t $trinAssem -O $outDir

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Translation to proteome lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"
echo "DONE"


sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize\
