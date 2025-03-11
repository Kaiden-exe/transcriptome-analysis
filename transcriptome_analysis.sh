#!/bin/bash
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025

############################
########## CHECKS ##########
############################
while [ $# -gt 0 ]; do
	case $1 in
    #TODO
		-h | --help)
			echo "Manual link: "
			echo "To run: bash transcriptome_analysis.sh -c config.sh"
			exit 0
        ;;
		-c | --config)
			if [ ! -f "$2" ]; then
				echo "Configuration file not found" >&2
				exit 1
			fi

			configFile=$2
			shift
		;;
		*)
			echo "Invalid option: $1" >&2
			exit 1
		;;
    esac
	shift
done

if [ ! -f "$configFile" ]; then
	echo "ERROR: Configuration file $configFile not found" >&2
	exit 1
fi

source $configFile

if [ ! -f "$manifest" ] ; then
	echo "ERROR: no manifest file found." >&2
    exit 1
fi

if [ ! -f "$referenceTSV" ] ; then
	echo "ERROR: no reference tsv file found." >&2
    exit 1
fi

if [ ! -f "$conditions" ] ; then
	echo "ERROR: no conditions tsv file found." >&2
    exit 1
fi

# Numbers for arrays
readfiles=$(wc -l $manifest)
readCount=${readfiles%% *}
speciesCount=$(cut -f4 $manifest | sort | uniq | wc -l)

#############################################
########## STEP 1: ALIGN WITH STAR ##########
#############################################

# Build indices
job0=$(sbatch -J STAR_index --cpus-per-task=8 --mem=250G -p fast -A tardi_genomic -o logfiles/STAR_index.%A_%a.out -e logfiles/STAR_index.%A_%a.error -t 00-23:00:00 --array=1-$speciesCount scripts/STAR_indices.sh $configFile)
jobID0=${job0##* }
echo STAR indexing job $jobID0

# Run alignment in array
job1=$(sbatch -J STAR --cpus-per-task=16 --mem=80G -p fast -A tardi_genomic -o logfiles/array_STAR.%A_%a.out -e logfiles/array_STAR.%A_%a.error -t 00-23:00:00 --array=1-$readCount --dependency=afterok:${jobID0} scripts/STAR_alignment.sh $configFile)
jobID1=${job1##* }
echo STAR job $jobID1

# Merge alignments
job2=$(sbatch -n 8 -J BAMmerge -N 1 -p fast -A tardi_genomic -o logfiles/samtools.%A.out -e logfiles/samtools.%A.error -t 00-23:00:00 --dependency=afterok:${jobID1} scripts/merge_bam.sh $configFile)
jobID2=${job2##* }
echo Merging job $jobID2


########################################################
########## STEP 2: CLUSTER GENES WITH TRINITY ##########
########################################################

ARRAY_NUM=$(( $speciesCount - 1)) 
job3=$(sbatch -J Trinity_guided -N 1 --cpus-per-task=24 --mem=250G -p fast -A tardi_genomic -o logfiles/trinity.%A_%a.out -e logfiles/trinity.%A_%a.error -t 00-23:00:00 --array=0-$ARRAY_NUM --dependency=afterok:${jobID2} scripts/trinity_guided.sh $configFile)
jobID3=${job3##* }
echo Trinity job $jobID3


###################################################
########## STEP 3: SALMON QUANTIFICATION ##########
###################################################

# Build indices
job4=$(sbatch -J salmon_indices -N 1 --mem-per-cpu=16G --cpus-per-task=24 -o logfiles/salmon_indices.%A_%a.out -e logfiles/salmon_indices.%A_%a.error -A tardi_genomic -p fast -t 0-23:00:00 --array=0-$ARRAY_NUM --dependency=afterok:${jobID3} scripts/salmon_indices.sh $configFile)
jobID4=${job4##* }
echo Salmon indexing job $jobID4

# Quantify
job5=$(sbatch -J salmon -N 1 --mem-per-cpu=10G --cpus-per-task=12 -o logfiles/salmon.%A_%a.out -e logfiles/salmon.%A_%a.error -A tardi_genomic -p fast --array=1-$readCount -t 0-23:00:00 --dependency=afterok:${jobID4} scripts/salmon_quanti.sh $configFile)
jobID5=${job5##* }
echo Salmon quantifying job $jobID5


##############################################
########## STEP 4: DEG/PCA ANALYSIS ##########
##############################################

job6=$(sbatch -J deg_pca -N 1 --mem=16G -n 12 -o logfiles/deg_pca.%A.out -e logfiles/deg_pca.%A.error -A tardi_genomic -p fast -t 0-23:00:00 --dependency=afterok:${jobID5} scripts/pca.sh $configFile)
jobID6=${job6##* }
echo "DEG/PCA" analysis job $jobID6


###################################################
########## STEP 5: TRANSLATE TO PROTEOME ##########
###################################################

job7=$(sbatch -J transdecoder -N 1 --mem=40G -n 1 -o logfiles/transdecoder.%A_%a.out -e logfiles/transdecoder.%A_%a.error -p fast -A tardi_genomic -t 0-23:00:00 --dependency=afterok:${jobID3} --array=0-$speciesCount scripts/transdecoder.sh $configFile)
jobID7=${job7##* }
echo TransDecoder job $jobID7


########################################
########## STEP 6: Annotation ##########
########################################

job8=$(sbatch -J eggnog-mapper --cpus-per-task=24 --mem=250G -o logfiles/emapper.%A_%a.out -e logfiles/emapper.%A_%a.error -A tardi_genomic -p fast -t 0-23:00:00 --array=0-$ARRAY_NUM --dependency=afterok:${jobID7} scripts/eggnog.sh $configFile)
jobID8=${job8##* }
echo eggNOG job $jobID8
