#!/bin/bash

configFile=$1
datePrefix=$(date +'%Y%m%d')
summaryFile="${datePrefix}_summary.txt"

if [ ! -f "$configFile" ]; then
	echo "ERROR: Configuration file not found" >&2
    echo "Usage: bash summary_transcriptome_analysis.sh config.sh"
	exit 1
fi

module load r
source $configFile

allSpecies=($(cut -f4 $manifest | sort | uniq))

echo "Analysed ${#allSpecies[@]} species" > $summaryFile
echo "Species: ${allSpecies[*]}" >> $summaryFile
echo "=========================" >> $summaryFile
echo -e "# Genes and isoforms identified by Trinity\n" >> $summaryFile
echo -e "species\ttotal_transcripts\ttotal_genes" >> $summaryFile

for species in ${allSpecies[@]} ; do
	mapFile=$trinityOut/$species/${species}.Trinity-GG.fasta.gene_trans_map
	transcripts=$(wc -l $mapFile)
	genes=$(cut -f1 $mapFile | sort | uniq | wc -l)

	echo -e "${species}\t${transcripts%% *}\t${genes}" >> $summaryFile
done

echo -e "\n=========================" >> $summaryFile
echo -e "# Mapping rates of reads to Trinity transcriptome as calculated by salmon\n" >> $summaryFile
echo -e "ID\tmapping_rate" >> $summaryFile

while read LINE ; do
	ID=$(echo "$LINE" | cut -f1)

	logFile=$salmonOut/$ID/logs/salmon_quant.log
	infoLine=$(grep 'Mapping rate =' $logFile)
	mappingRate=${infoLine##* }

	echo -e "${ID}\t${mappingRate}" >> $summaryFile
done <"$manifest"

echo -e "\n=========================" >> $summaryFile
echo -e "# Amount of DEGs with p-value <= 0.05\n" >> $summaryFile
echo -e "species\tDEGs\ttotal_genes" >> $summaryFile

for species in ${allSpecies[@]} ; do
	degFile=$DEGout/${species}_DESeq_results.txt
	degs=$(Rscript --vanilla scripts/count_DEGs.R $degFile)
	totalGenes=$(cat $degFile | wc -l )
	echo -e "${species}\t${degs}\t$(( $totalGenes - 1 ))" >> $summaryFile
done

echo -e "\n=========================" >> $summaryFile
echo -e "# Amount of unannotated genes\n" >> $summaryFile
echo -e "species\ttotal\tunannotated_genes" >> $summaryFile

for species in ${allSpecies[@]} ; do
	pepFile=$transdecoderOut/$species/${species}.Trinity-GG.fasta.transdecoder.pep
	annotationFile=$eggnogOut/$species/${species}.emapper.annotations

	total=$(grep '>' $pepFile | wc -l)
	annotated=$(grep "^[^#]" $annotationFile | wc -l)
	unannotated=$(($total - $annotated))

	echo -e "${species}\t${total}\t${unannotated}" >> $summaryFile
done
