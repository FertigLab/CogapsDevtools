args <- commandArgs(trailingOnly=TRUE)
fname <- args[1]
seed <- as.numeric(args[2])
numRows <- as.numeric(args[3])
numCols <- as.numeric(args[4])

library(CoGAPS)
data(GIST)
set.seed(seed)
data <- matrix(sample(GIST.matrix, size=numRows*numCols, replace=TRUE), nrow=numRows)
saveRDS(data, file=fname)

