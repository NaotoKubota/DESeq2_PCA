library(DESeq2)

args <- commandArgs(trailingOnly = T)
experiment_table <- args[1]
counts_table <- args[2]
pca_table <- args[3]
REFGROUP <- args[4]
EXPGROUP <- args[5]
output <- args[6]

# Read
experiment <- read.table(

    experiment_table,
    sep = "\t",
    head = T,
    check.names = FALSE

)

counts <- read.table(

    counts_table,
    sep = "\t",
    head = T,
    row.names = "gene_name",
    check.names = FALSE,
    stringsAsFactors = FALSE

)
counts_t <- t(counts)

pca <- read.table(

	pca_table,
	sep = "\t",
	head = T,
	check.names = FALSE

)

# Merge
merged <- merge(counts_t, experiment, by.x = 0, by.y = "sample")
# Merge with pca
merged <- merge(merged, pca, by.x = "Row.names", by.y = "sample")
# Filter
merged <- merged[merged$group == REFGROUP | merged$group == EXPGROUP, ]
# Group and PCs
group <- data.frame(con = factor(merged$group), PC1 = merged$PC1, PC2 = merged$PC2, PC3 = merged$PC3)
# Count matrix
counts <- merged[, -which (colnames(merged) %in% c("bam", "group", "PC1", "PC2", "PC3"))]
head(counts[, 1:5])
rownames(counts) <- counts$Row.names
counts <- counts[, colnames(counts) != "Row.names"]
counts <- t(counts)
counts <- as.matrix(counts)


# At least six counts
counts <- counts[apply(counts, 1, sum)>6,]

# DEseq
dds <- DESeqDataSetFromMatrix(countData = counts, colData = group, design = ~ con + PC1 + PC2 + PC3)
dds$con <- relevel(dds$con, ref = REFGROUP)
dds <- DESeq(dds)
res <- results(dds)
res$gene_name <- row.names(res)
res <- res[, c("gene_name", "baseMean", "log2FoldChange", "lfcSE", "stat", "pvalue", "padj")]
res <- res[order(res$padj), ]

# save
write.table(

    res,
    file = output,
    sep = "\t",
    row.names = F,
    col.names = T,
    quote = F

)
