#!/bin/bash
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025
module load singularity
echo "$SLURM_ARRAY_TASK_ID"

# Config file
source $1


allSpecies=($(cut -f4 $manifest | sort | uniq))
species=${allSpecies[$SLURM_ARRAY_TASK_ID]}
bamFile=$(realpath "$alignmentDir/${species}_merged.bam")
output=$trinityOut/$species

start=$EPOCHREALTIME
mkdir -p $output
pushd $output
singularity exec --bind $DIR $DIR/bin/trinityrnaseq_2.15.1.sif Trinity --max_memory 200G --CPU 24 --full_cleanup \
 --genome_guided_bam $bamFile --genome_guided_max_intron 10000 --output trinity_${species}

# Logging 
end=$EPOCHREALTIME
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "Clustering $species into genes lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"

# Add species ID to all the genes 
# Remove also the trinity pefix (adding was necessary or trinity will throw an error) 
sed "s/>/>$species|/g" "trinity_$species.Trinity-GG.fasta" > "$species.Trinity-GG.fasta"
sed "s/TRINITY/$species|TRINITY/g" "trinity_$species.Trinity-GG.fasta.gene_trans_map" > "$species.Trinity-GG.fasta.gene_trans_map"
popd
echo "DONE"


sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
