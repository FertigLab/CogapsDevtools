args <- commandArgs(trailingOnly=TRUE)
print(args)
allBenchmarks <- readRDS(file=args[1])
thisResult <- readRDS(file=args[2])
numRows <- as.numeric(args[3])
numCols <- as.numeric(args[4])
numPatterns <- as.numeric(args[5])
numIterations <- as.numeric(args[6])

createBenchmark <- function(res)
{
	data.frame(runningTime=res@metadata$totalRunningTime,
		nRow=numRows,
		nCol=numCols,
		nPatterns=numPatterns,
		nIterations=numIterations
	)
}

allBenchmarks <- rbind(allBenchmarks, createBenchmark(thisResult))
saveRDS(allBenchmarks, file=args[1])

