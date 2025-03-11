#!/usr/bin/env Rscript
# Author: Kaiden R. Sewradj
# Last update: 10/03/2025

args = commandArgs(trailingOnly=TRUE)
# 1st argument = file 

degs = read.delim(args[1])
write(nrow(degs[degs$pvalue <= 0.05,]), stdout())
