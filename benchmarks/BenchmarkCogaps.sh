#!/bin/bash

# parse command line parameters
RUN_QUICK_BM=true
for i in "$@"
do
    case $i in
        --bm-threads*)
        BENCHMARK_THREADS=true
        ;;

        --bm-distributed*)
        BENCHMARK_DISTRIBUTED=true
        ;;

        --perf-stats*)
        REPORT_PERF_STATS=true
        ;;

        --bm-sparse*)
        BENCHMARK_SPARSE=true
        ;;

        --bm-scaling*)
        BENCHMARK_SCALING=true
        ;;

        --bm-large*)
        BENCHMARK_LARGE=true
        ;;
    
        --bm-compiler*)
        BENCHMARK_COMPILER=true
        ;;

        --full*)
        RUN_FULL_BM=true
        ;;

        --verbose*)
        VERBOSE_OUTPUT=true
        ;;

        *)
            echo "ERROR: unrecognized option"
            echo "${i%=*}"
            exit 1
        ;;
    esac
done

# set up environment to suppress output unless --verbose is passed
exec 3>&1
exec 4>&2
if [ ! "${VERBOSE_OUTPUT}" = true ]; then
    exec 1>/dev/null
    exec 2>/dev/null
fi

# create a blank benchmark file
R -q -e "df <- data.frame(); saveRDS(df, file='allBenchmarks.rds');"

# benchmark how cogaps scales to larger data sizes
if [ "${BENCHMARK_SCALING}" = true ]; then
    RUN_QUICK_BM=false
    echo "Benchmarking how CoGAPS scales" 1>&3 2>&4
    Rscript SingleCogapsBenchmark.R --benchmarks.file=allBenchmarks.rds \
        --num.data.rows=20 --num.data.cols=5000 --seed=123 --num.patterns=10 \
        --num.iterations=500
    Rscript SingleCogapsBenchmark.R --benchmarks.file=allBenchmarks.rds \
        --num.data.rows=20 --num.data.cols=10000 --seed=123 --num.patterns=10 \
        --num.iterations=500
    Rscript SingleCogapsBenchmark.R --benchmarks.file=allBenchmarks.rds \
        --num.data.rows=20 --num.data.cols=20000 --seed=123 --num.patterns=10 \
        --num.iterations=500
fi

# run a quick benchmark
if [ "${RUN_QUICK_BM}" = true ]; then
    echo "Running a quick benchmark" 1>&3 2>&4
    Rscript SingleCogapsBenchmark.R --benchmarks.file=allBenchmarks.rds \
        --num.data.rows=20 --num.data.cols=10000 --seed=123 --num.patterns=10 \
        --num.iterations=500
    Rscript SingleCogapsBenchmark.R --benchmarks.file=allBenchmarks.rds \
        --num.data.rows=750 --num.data.cols=750 --seed=123 --num.patterns=25 \
        --num.iterations=500
fi

# print benchmark results
R --slave -e 'bm <- readRDS("allBenchmarks.rds"); print(bm)' 1>&3 2>&4
rm allBenchmarks.rds