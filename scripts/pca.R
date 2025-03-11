#!/usr/bin/env Rscript
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025

args = commandArgs(trailingOnly=TRUE)
# 1st = Conditions.tsv
# 2nd = salmonOut
# 3rd = outDEG
# 4th = manifest.tsv

library(tximport)
library(DESeq2)
library(stringr)
library(ggplot2)
library(factoextra)

### Prepare coldata and loop through all species ####
conditiondf = read.table(args[1],h=T,sep='\t')
conditiondf$condition = as.factor(conditiondf$condition)
conditiondf$batch = as.factor(conditiondf$batch)
manifest = read.delim(args[4], header=F)
colnames(manifest) = c("ID", "reads1", "reads2", "speciesID")
species = unique(manifest$speciesID)

for (specie in species) {
  ### Import salmon files ###
  IDs = manifest[manifest$speciesID == specie, c("ID")]
  files = paste(args[2], IDs, "quant.sf", sep="/")
  names(files) = IDs

  # Build 2 column table (gene and isoform) 
  genes = read.table(files[1], header=T, sep = '\t')
  genes$geneID = str_split_fixed(genes$Name, "_i", 2)[,1]
  genes = genes[,c("Name", "geneID")]

  # Import
  tximported = tximport(files, type = "salmon", tx2gene = genes)
  countsM = tximported$counts
  countsM = round(countsM)

  ### Create DESeq2 data set ###
  # colData 
  coldata = conditiondf[conditiondf$ID %in% IDs, c("condition", 'batch')]
  dds <- tryCatch({
    # Take into account batch effect 
    DESeqDataSetFromMatrix(countData = countsM,
                           colData = coldata,
                           design = ~ batch + condition)
  }, error = function(e) {
    # Dismiss batch effect if matrix not full rank 
    write("WARNING: Matrix not full rank, batch effect ignored", stderr())
    DESeqDataSetFromMatrix(countData = countsM,
                           colData = coldata,
                           design = ~ condition)
  })

  ### Pre-filter ###
  # (Optional) Filter out low expressed genes
  # smallestGroupSize <- 4
  # keep <- rowSums(counts(dds) >= 12) >= smallestGroupSize
  # dds <- dds[keep,]

  # Put control condition first
  dds$condition <- relevel(dds$condition, ref = "0Gy")

  ### DESeq analysis ###
  dds <- DESeq(dds)
  res <- results(dds)

  # Order results by pvalue
  resOrdered <- res[order(res$pvalue),]

  # Create export table
  outtable = resOrdered
  outtable$geneID = rownames(outtable)
  outtable<-outtable[,c(7,1:6)]
  write.table(as.data.frame(outtable), file=paste(args[3], "/", specie, "_DESeq_results.txt", sep="")
              , sep = "\t", quote = FALSE, row.names = F)

  ### PCA Analysis ###
  pcanalysis <- vst(dds, blind=FALSE)
  p = plotPCA(pcanalysis, intgroup=c("condition"))
  save(pcanalysis, res, dds, 
       file=paste(args[3], '/', specie, '_results.RData', sep=""))
  ggsave(paste(args[3], "/", specie, "_PCA_Plot.png", sep=""), plot = p)

  ### Volcano plot ###
  df = as.data.frame(res[, c("log2FoldChange", "pvalue")])
  df$geneID = rownames(df)
  row.names(df) = NULL

  # Plot
  p <- ggplot(data=df, aes(x=log2FoldChange, y=-log10(pvalue))) + 
    geom_point() +
    geom_vline(xintercept=c(-0.6, 0.6), col="red") +
    geom_hline(yintercept=-log10(0.05), col="red") +
    ggtitle(paste("Volcano plot differential expression ", specie, sep=""))
  ggsave(paste(args[3], "/", specie, "_VolcanoPlot.png", sep=""), plot = p)
}
