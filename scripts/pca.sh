#!/bin/bash
module load r/4.4.1

#Config file 
source $1

start=$EPOCHREALTIME
mkdir -p $DEGout
Rscript --vanilla scripts/pca.R $conditions $salmonOut $DEGout $manifest

# Logging 
end=$EPOCHREALTIME
speciesCnt=$(cut -f4 $manifest | sort | uniq | wc -l)
runtime=$( echo "$end - $start" | bc -l )
HOURS=$(echo "$runtime / 3600" | bc)
MINS=$(echo "($runtime / 60) % 60" | bc)
SECS=$(echo "$runtime % 60" | bc)
echo "DEG and PCA analysis of $speciesCnt species lasted ${HOURS}hrs ${MINS}mins ${SECS%.*}secs"

echo "DONE"
sstat -j $SLURM_JOB_ID.batch --format=JobID,MaxVMSize
