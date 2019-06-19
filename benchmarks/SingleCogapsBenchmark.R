library(getopt)
library(optparse)

# these are the allowed command line arguments, the default value is always
# NULL and it is up to the script to handle missing arguments and set other
# default values
arguments <- commandArgs(trailingOnly=TRUE)
option_list <- list(
    make_option("--benchmarks.file", dest="benchmarks.file", default=NULL),
    make_option("--num.data.rows", dest="num.data.rows", default=NULL),
    make_option("--num.data.cols", dest="num.data.cols", default=NULL),
    make_option("--num.patterns", dest="num.patterns", default=NULL),
    make_option("--num.iterations", dest="num.iterations", default=NULL),
    make_option("--seed", dest="seed", default=NULL),
    make_option("--distributed.method", dest="distributed.method", default=NULL),
    make_option("--num.sets", dest="num.sets", default=NULL),
    make_option("--transpose.data", dest="transpose.data", default=NULL),
    make_option("--num.threads", dest="num.threads", default=NULL),
    make_option("--asynchronous.updates", dest="asynchronous.updates", default=NULL),
    make_option("--output.frequency", dest="output.frequency", default=NULL),
    make_option("--github.tag", dest="github.tag", default=NULL)
)

# parse command line arguments, remove the help argument for nicer printing
opts <- parse_args(OptionParser(option_list=option_list),
    positional_arguments=FALSE, args=arguments)
opts$help <- NULL

# set empty string arguments as NULL, so that you can call this script with
# potentially empty environment variables,
# i.e. `Rscript run_cogaps.R --data.file=${INPUT_FILE}`
for (option in names(opts))
{
    if (opts[[option]] == "")
        opts[[option]] <- NULL
}

# convert non-string parameters
convertToNumeric <- function(optionList, arg)
{
    if (!is.null(optionList[[arg]]))
        optionList[[arg]] <- as.numeric(optionList[[arg]])
    return(optionList)
}

convertToBool <- function(optionList, arg)
{
    falseLables = c('0', 'FALSE', 'False', 'false', 'No', 'no', 'N', 'n')
    if (!is.null(optionList[[arg]]))
        optionList[[arg]] <- !(optionList[[arg]] %in% falseLables)
    return(optionList)
}

opts <- convertToNumeric(opts, "num.data.rows")
opts <- convertToNumeric(opts, "num.data.cols")
opts <- convertToNumeric(opts, "num.patterns")
opts <- convertToNumeric(opts, "num.iterations")
opts <- convertToNumeric(opts, "seed")
opts <- convertToNumeric(opts, "num.sets")
opts <- convertToNumeric(opts, "num.threads")
opts <- convertToNumeric(opts, "output.frequency")
opts <- convertToNumeric(opts, "asynchronous.updates")
opts <- convertToBool(opts, "transpose.data")

# make sure required arguments are given
if (is.null(opts$benchmarks.file))
    stop("Must provide --benchmarks.file")
if (is.null(opts$num.patterns))
    stop("Must provide --num.patterns")
if (is.null(opts$num.iterations))
    stop("Must provide --num.iterations")
    
# check if a specific version of CoGAPS is requested, try to install it
if (!is.null(opts$github.tag))
{
    cat("Trying to load CoGAPS (", opts$github.tag, ") from github\n", sep="")
    BiocManager::install("FertigLab/CoGAPS", ask=FALSE, ref=opts$github.tag)
}

# load CoGAPS
library(CoGAPS)

# create default parameters
params <- CogapsParams()

# command line arguments take precedent over defaults
setParamValue <- function(params, name, value)
{
    if (!is.null(value))
        params <- setParam(params, name, value)
    return(params)
}
params <- setParamValue(params, "nPatterns", opts$num.patterns)
params <- setParamValue(params, "nIterations", opts$num.iterations)
params <- setParamValue(params, "seed", opts$seed)
params <- setParamValue(params, "distributed", opts$distributed.method)

# special command line arguments
if (!is.null(opts$num.sets))
    params <- setDistributedParams(params, nSets=opts$num.sets)

# some arguments aren't in the parameters, set defaults here
getValue <- function(value, default) ifelse(is.null(value), default, value)
transposeData <- getValue(opts$transpose.data, default=FALSE)
nThreads <- getValue(opts$num.threads, default=1)
outputFrequency <- getValue(opts$output.frequency, default=1000)
asynchronousUpdates <- getValue(opts$asynchronous.updates, default=1)
asynchronousUpdates <- ifelse(asynchronousUpdates == 0, FALSE, TRUE)

# create the data
data(GIST)
bmData <- matrix(sample(GIST.matrix, size=opts$num.data.rows * opts$num.data.cols, replace=TRUE),
    nrow=opts$num.data.rows)

# run cogaps and save result
gapsResult <- CoGAPS(data=bmData, params=params, nThreads=nThreads,
    transposeData=transposeData, outputFrequency=outputFrequency)
#    asynchronousUpdates=asynchronousUpdates)
bm <- data.frame(runningTime=gapsResult@metadata$totalRunningTime,
                 nRow=nrow(bmData),
                 nCol=ncol(bmData),
                 nPatterns=opts$num.patterns,
                 nIterations=opts$num.iterations)

allBenchmarks <- readRDS(opts$benchmarks.file)
allBenchmarks <- rbind(allBenchmarks, bm)
saveRDS(allBenchmarks, file=opts$benchmarks.file)

    

