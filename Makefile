R_CPP_SOURCES := $(wildcard R_Package/src/*.cpp) \
	$(wildcard R_Package/src/atomic/*.cpp) \
	$(wildcard R_Package/src/data_structures/*.cpp) \
	$(wildcard R_Package/src/file_parser/*.cpp) \
	$(wildcard R_Package/src/gibbs_sampler/*.cpp) \
	$(wildcard R_Package/src/math/*.cpp) \
	$(wildcard R_Package/src/utils/*.cpp)

R_CPP_SOURCES := $(filter-out R_Package/src/RcppExports.cpp, $(R_CPP_SOURCES))
R_CPP_SOURCES := $(filter-out R_Package/src/atomic/ProposalQueue.cpp, $(R_CPP_SOURCES))
R_CPP_SOURCES := $(filter-out R_Package/src/atomic/ConcurrentAtomicDomain.cpp, $(R_CPP_SOURCES))
R_CPP_SOURCES := $(filter-out R_Package/src/data_structures/HybridVector.cpp, $(R_CPP_SOURCES))

R_CPP_HEADERS = \
	$(wildcard R_Package/src/*.h) \
	$(wildcard R_Package/src/atomic/*.h) \
	$(wildcard R_Package/src/data_structures/*.h) \
	$(wildcard R_Package/src/file_parser/*.h) \
	$(wildcard R_Package/src/gibbs_sampler/*.h) \
	$(wildcard R_Package/src/math/*.h) \
	$(wildcard R_Package/src/utils/*.h)

INCLUDES = \
	-IR_Package/src/include \
	-I"/usr/share/R/include" \
	-I"/home/tom/R/x86_64-pc-linux-gnu-library/3.5/Rcpp/include"

DEFINES = -DNDEBUG -DBOOST_MATH_PROMOTE_DOUBLE_POLICY=0 -D__GAPS_R_BUILD__
CFLAGS = -fpic -g -O2 -fstack-protector-strong -Wformat -Wdate-time -fopenmp=libomp \
	-march=native -Werror=format-security -D_FORTIFY_SOURCE=2 -Werror -x c++

R_CPP_LINT_TARGETS = $(addsuffix .lint, $(R_CPP_SOURCES)) \
	$(addsuffix .lint, $(R_CPP_HEADERS))

CLANG_TIDY_CHECKS := *,-llvm-header-guard,-android*,-cppcoreguidelines-pro-bounds-pointer-arithmetic,-google-readability-todo,-modernize-use-auto,-cppcoreguidelines-pro-type-vararg,-google-runtime-references,-modernize-loop-convert,-hicpp-use-equals-default,-hicpp-use-equals-delete,-modernize-use-equals-default,-modernize-use-equals-delete,-fuchsia-default-arguments,-modernize-return-braced-init-list,-modernize-use-default,-modernize-use-nullptr

LINT_COLOR := \033[0;34m
NO_COLOR := \033[m

N_CORES := 1
N_COMMITS := 5

all : install_R 

## Targets for R package

install_R : build_R
	cd R_build && \
	R CMD INSTALL --configure-args="$(CONFIG_ARGS)" CoGAPS_*.tar.gz && \
	cd ..

R_configure_script :
	cd R_Package && \
	autoreconf -i || true && \
	rm -f aclocal.m4 && \
	rm -rf autom4te.cache && \
	chmod ugo+x configure && \
	cd ..

build_R :
	mkdir -p R_build
	cd R_build && \
	rm -f CoGAPS_*.tar.gz && \
	R CMD build --no-build-vignettes ../R_Package && \
	cd ..

build_R_with_vignettes :
	mkdir -p R_build
	cd R_build && \
	rm -f CoGAPS_*.tar.gz && \
	R CMD build ../R_Package && \
	cd ..

vignette : build_R_with_vignettes
	cd R_build && \
	rm -rf vignette_temp && \
	mkdir vignette_temp && \
	tar -xf CoGAPS_*.tar.gz -C vignette_temp && \
	#cp vignette_temp/CoGAPS/inst/doc/CoGAPS.html .. && \
	cp vignette_temp/CoGAPS/inst/doc/DataInput.html .. && \
	rm -rf vignette_temp && \
	cd ..

docs_R : 
	sed -i "1s/.*/# CoGAPS $(shell awk -e '/^Version:/ {print $2}' R_Package/DESCRIPTION)/" R_Package/README.md
	R -e 'devtools::document("./R_Package")'
	rm -f R_Package/src/Makevars R_Package/config.log R_Package/config.status

RcppInterface : 
	R -e 'Rcpp::compileAttributes("./R_Package")'
	rm -f R_Package/src/Makevars R_Package/config.log R_Package/config.status

test_R_package : 
	R -e "devtools::load_all('R_Package'); devtools::test('R_Package')"
	rm -f R_Package/src/Makevars R_Package/config.log R_Package/config.status

test_R_package_debug : 
	@make install_R CONFIG_ARGS='--enable-debug'
	R -e 'library(CoGAPS); data(GIST); testDataFrame <- GIST.data_frame; testMatrix <- GIST.matrix; res <- CoGAPS(testDataFrame, nIterations=100,outputFrequency=50, seed=1, messages=FALSE, distributed="genome-wide")'

run_cpp_tests:
	R -e 'library(CoGAPS); data(GIST); gistCsvPath <<- system.file("extdata/GIST.csv", package="CoGAPS"); gistTsvPath <<- system.file("extdata/GIST.tsv", package="CoGAPS"); gistMtxPath <<- system.file("extdata/GIST.mtx", package="CoGAPS"); gistGctPath <<- system.file("extdata/GIST.gct", package="CoGAPS"); CoGAPS:::run_catch_unit_tests()'

cpp_tests:
	@make install_R CONFIG_ARGS='--enable-cpp-tests --enable-debug --disable-simd'
	@make run_cpp_tests

internal_cpp_tests : 
	@make install_R CONFIG_ARGS='--enable-cpp-tests --enable-internal-tests --enable-debug --disable-simd'
	@make run_cpp_tests

gdb_internal_cpp_tests : 
	@make install_R CONFIG_ARGS='--enable-internal-tests --enable-debug --disable-simd'
	R -d gdb -e 'library(CoGAPS); data(GIST); gistCsvPath <<- system.file("extdata/GIST.csv", package="CoGAPS"); gistTsvPath <<- system.file("extdata/GIST.tsv", package="CoGAPS"); gistMtxPath <<- system.file("extdata/GIST.mtx", package="CoGAPS"); gistGctPath <<- system.file("extdata/GIST.gct", package="CoGAPS"); CoGAPS:::run_catch_unit_tests()'

check_R_package : build_R_with_vignettes
	cd R_build && \
	R CMD check --no-build-vignettes CoGAPS_*.tar.gz && \
	cd ..

bioc_check : build_R_with_vignettes
	cd R_build && \
	R CMD BiocCheck CoGAPS_*.tar.gz && \
	cd ..

check_for_debug_statements :
	@if [ $(grep "DEBUG_PING" -r R_Package/src/ | wc -l) > 1 ]; then\
		echo "ERROR: DEBUG_PING lines found in source code";\
	fi

all_examples : 
	@make example_R
	@make example_R_from_file
	@make example_R_gw
	@make example_R_gw_from_file
	@make example_R_sc
	@make example_R_sc_from_file

default_mtx_read:
	R -e 'eat <- Matrix::readMM("SubsetRetinaData.mtx")'

benchmark_mtx_read:
	R -e 'CoGAPS::CoGAPS("SubsetRetinaData.mtx", sparseOptimization=FALSE, nIterations=100)'

example_R :
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, nPatterns=4, nIterations=5000, outputFrequency=1000, seed=1234, nThreads=$(N_CORES))'

sparse_example_R :
	R -e 'library(CoGAPS); data(GIST); CoGAPS(floor(GIST.matrix), nPatterns=4, nIterations=5000, outputFrequency=1000, seed=1234, sparseOptimization=TRUE, nThreads=$(N_CORES))'

example_R_from_file :
	R -e 'library(CoGAPS); CoGAPS(system.file("extdata/GIST.csv", package="CoGAPS"), nPatterns=4, nIterations=2000, outputFrequency=1000, seed=1234, nThreads=$(N_CORES))'

example_R_gw :
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, distributed="genome-wide", nPatterns=4, nIterations=2000, outputFrequency=1000, seed=1234)'

example_R_gw_from_file :
	R -e 'library(CoGAPS); CoGAPS(system.file("extdata/GIST.tsv", package="CoGAPS"), distributed="genome-wide", nPatterns=4, nIterations=2000, outputFrequency=1000, seed=1234)'

example_R_sc :
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, transposeData=TRUE, distributed="single-cell", nPatterns=4, nIterations=2000, outputFrequency=1000, seed=1234, singleCell=TRUE)'

example_R_sc_from_file :
	R -e 'library(CoGAPS); CoGAPS(system.file("extdata/GIST.mtx", package="CoGAPS"), transposeData=TRUE, distributed="single-cell", nPatterns=7, nIterations=20000, outputFrequency=5000, seed=1234, singleCell=TRUE)'

example_R_checkpoint :
	R -e 'library(CoGAPS); data(GIST); run1 <- CoGAPS(GIST.matrix, checkpointInterval=501, checkpointOutFile="test.out", messages=TRUE, outputFrequency=100); run2 <- CoGAPS(GIST.matrix, checkpointInFile="test.out", messages=TRUE, outputFrequency=100);' || true && rm test.out

valgrind_R :
	R -d valgrind -e 'library(CoGAPS); data(GIST); eat <- CoGAPS("SampleData/GIST.mtx", nIterations=2000, outputFrequency=250)'

gdb_R_example :
	R -d gdb -e 'library(CoGAPS); data(GIST); eat <- CoGAPS("SampleData/GIST.mtx", nIterations=2000, outputFrequency=250, seed=1234, nThreads=$(N_CORES))'

compile_in_place :
	R -e 'devtools::load_all("./R_Package")'

test_data_structures :
	@make install_R_debug
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, nPatterns=4, nIterations=100, outputFrequency=25, seed=1234, sparseOptimization=FALSE, asynchronousUpdates=TRUE)'
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, nPatterns=4, nIterations=100, outputFrequency=25, seed=1234, sparseOptimization=TRUE, asynchronousUpdates=TRUE)'
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, nPatterns=4, nIterations=100, outputFrequency=25, seed=1234, sparseOptimization=FALSE, asynchronousUpdates=FALSE)'
	R -e 'library(CoGAPS); data(GIST); CoGAPS(GIST.matrix, nPatterns=4, nIterations=100, outputFrequency=25, seed=1234, sparseOptimization=TRUE, asynchronousUpdates=FALSE)'
	@make install_R

long_matrix_profile_R:
	mkdir -p profiles
	mkdir -p profiles/R
	mkdir -p profiles/R/long_matrix/	
	R -d "valgrind --tool=callgrind" -e 'library(CoGAPS); data(GIST); data <- matrix(sample(GIST.matrix, size=20*5000, replace=TRUE), nrow=20); CoGAPS(data, nIterations=2000, outputFrequency=250)'
	mv callgrind.out.* profiles/R/long_matrix

sparse_profile_R :
	mkdir -p profiles
	mkdir -p profiles/R
	R -d "valgrind --tool=callgrind" -e 'library(CoGAPS); set.seed(42); data <- matrix(rnbinom(200 * 200, 10, 0.7), nrow=200, ncol=200); data[runif(length(data), 0, 1) < 0.75] <- 0; CoGAPS(data, nPatterns=10, nIterations=2000, outputFrequency=250, sparseOptimization=TRUE, singleCell=TRUE, seed=123)'
	mv callgrind.out.* profiles/R

sparse_profile_R_97 :
	mkdir -p profiles
	mkdir -p profiles/R
	R -d "valgrind --tool=callgrind" -e 'library(CoGAPS); set.seed(42); data <- matrix(rnbinom(577 * 577, 10, 0.7), nrow=577, ncol=577); data[runif(length(data), 0, 1) < 0.97] <- 0; CoGAPS(data, nPatterns=10, nIterations=2000, outputFrequency=250, sparseOptimization=TRUE, singleCell=TRUE, seed=123)'
	mv callgrind.out.* profiles/R

benchmark_R :
	R -e 'library(CoGAPS); data(GIST); set.seed(1234); data <- matrix(sample(GIST.matrix, size=500*500, replace=TRUE), nrow=500); CoGAPS(data, nIterations=5000, outputFrequency=1000, seed=1234, nThreads=$(N_CORES))'

sparse_benchmark_R :
	R -e 'library(CoGAPS); set.seed(42); data <- matrix(rnbinom(500 * 500, 10, 0.7), nrow=500); data[runif(length(data), 0, 1) < 0.75] <- 0; CoGAPS(data, nPatterns=20, nIterations=2000, outputFrequency=500, sparseOptimization=TRUE, singleCell=TRUE, seed=123)'

sparse_benchmark_R_big :
	R -e 'library(CoGAPS); set.seed(42); data <- matrix(rnbinom(3200 * 4500, 10, 0.7), nrow=3200); data[runif(length(data), 0, 1) < 0.97] <- 0; CoGAPS(data, nPatterns=80, nIterations=2000, outputFrequency=250, sparseOptimization=TRUE, singleCell=TRUE, seed=123)'

set_R_compiler_gcc :
	@printf "CC=ccache gcc\nCXX=ccache g++\nMAKEFLAGS=\n" > ~/.R/Makevars

set_R_compiler_gcc_6 :
	@printf "CC=ccache gcc-6\nCXX=ccache g++-6\nMAKEFLAGS=\n" > ~/.R/Makevars

set_R_compiler_clang :
	@printf "CC=ccache clang\nCXX=ccache clang++\nMAKEFLAGS=\n" > ~/.R/Makevars

set_R_compiler_clang_6 :
	@printf "CC=ccache clang-6.0\nCXX=ccache clang++-6.0\nMAKEFLAGS=\n" > ~/.R/Makevars

install_R_no_simd : build_R
	@make install_R CONFIG_ARGS=--disable-simd

install_R_no_openmp : build_R
	@make install_R CONFIG_ARGS=--disable-openmp

install_R_debug : build_R
	@make install_R CONFIG_ARGS=--enable-debug

install_R_with_warnings : build_R
	@make install_R CONFIG_ARGS=--enable-warnings

test_R_install : build_R
	@make install_R
	@make install_R CONFIG_ARGS='--enable-warnings'
	@make install_R CONFIG_ARGS='--enable-warnings --disable-simd'
	@make install_R CONFIG_ARGS='--enable-warnings --disable-openmp'

test_R_gcc_install : set_R_compiler_gcc
	@make test_R_install --no-print-directory

test_R_clang_install : set_R_compiler_clang
	@make test_R_install --no-print-directory

lint_R :
	R -e 'eat <- sapply(list.files("R_Package/R"), function(f) lintr::lint(paste("R_Package/R/", f, sep=""))); if (is.null(warnings())) {message("Lint Free!")} else {stop("Error: Not Lint Free")}'

lint_R_Package_cpp : $(R_CPP_LINT_TARGETS)

lint_R_Package : lint_R_Package_cpp lint_R

full_R_test_suite : test_R_package check_R_package lint_R_Package
	@make test_R_gcc_install
	@make install_R CONFIG_ARGS='--enable-debug'
	@make all_examples
	@make test_R_clang_install
	@make install_R CONFIG_ARGS='--enable-debug'
	@make all_examples

recent_R_commits: 
	@cd R_Package && \
	git log -$(N_COMMITS) && \
	cd ..

%.cpp.lint : %.cpp
	@echo "$(LINT_COLOR)linting" $(basename $@) "$(NO_COLOR)"
	@clang-tidy $(basename $@) $(LINT_FLAGS) -checks=$(CLANG_TIDY_CHECKS) -- $(INCLUDES) \
	$(DEFINES) $(CFLAGS)

%.h.lint : %.h
	@echo "$(LINT_COLOR)linting" $(basename $@) "$(NO_COLOR)"
	@clang-tidy $(basename $@) $(LINT_FLAGS) -checks=$(CLANG_TIDY_CHECKS) -- $(INCLUDES) \
	$(DEFINES) $(CFLAGS)

clean :
	rm -f R_Package/src/*.so
	rm -f R_Package/src/*.o
	rm -f R_Package/src/atomic/*.o
	rm -f R_Package/src/cpp_tests/*.o
	rm -f R_Package/src/data_structures/*.o
	rm -f R_Package/src/file_parser/*.o
	rm -f R_Package/src/gibbs_sampler/*.o
	rm -f R_Package/src/math/*.o
	rm -f R_Package/src/utils/*.o
	rm -f R_Package/src/Makevars
	rm -f R_Package/config.log R_Package/config.status

## Targets for standalone CLI

full_clean_CLI_build_install :
	@make clean_CLI
	@make CLI_configure_script
	@make configure_CLI
	@make build_CLI
	@make install_CLI

clean_CLI :
	rm -rf CLI_build

CLI_configure_script :
	cd Standalone_CLI && \
	autoreconf -i && \
	rm -rf autom4te.cache && \
	cd ..

configure_CLI : clean_CLI
	cd Standalone_CLI && \
	touch Makefile.in aclocal.m4 compile config.guess config.h.in config.sub configure depcomp install-sh missing && \
	cd ..
	mkdir CLI_build
	cd CLI_build && \
	../Standalone_CLI/configure $(CONFIG_ARGS) && \
	cd ..

build_CLI :
	cd CLI_build && \
	make -j $(N_CORES) && \
	cd ..

install_CLI : build_CLI
	cp CLI_build/cogaps /usr/local/bin/

test_CLI :
	@make configure_CLI CONFIG_ARGS="$(CONFIG_ARGS)"
	@make build_CLI
	@make example_CLI N_CORES=$(N_CORES)

test_CLI_debug :
	@make test_CLI CONFIG_ARGS="$(CONFIG_ARGS) --enable-debug" N_CORES=$(N_CORES)

test_CLI_asan : 
	@make test_CLI CONFIG_ARGS="$(CONFIG_ARGS) CC=clang CXX=clang++ --enable-debug=asan" N_CORES=$(N_CORES)

test_CLI_lsan : 
	@make test_CLI CONFIG_ARGS="$(CONFIG_ARGS) --enable-debug=lsan" N_CORES=$(N_CORES)

test_CLI_usan : 
	@make test_CLI CONFIG_ARGS="$(CONFIG_ARGS) --enable-debug=usan" N_CORES=$(N_CORES)

test_CLI_tsan : 
	@make test_CLI CONFIG_ARGS="$(CONFIG_ARGS) --enable-debug=tsan" N_CORES=$(N_CORES)

test_CLI_all_sanitizers : 
	@make test_CLI_tsan CONFIG_ARGS=$(CONFIG_ARGS) N_CORES=$(N_CORES)
	@make test_CLI_asan CONFIG_ARGS=$(CONFIG_ARGS) N_CORES=$(N_CORES)
	@make test_CLI_lsan CONFIG_ARGS=$(CONFIG_ARGS) N_CORES=$(N_CORES)
	@make test_CLI_usan CONFIG_ARGS=$(CONFIG_ARGS) N_CORES=$(N_CORES)
	@make test_CLI_debug CONFIG_ARGS=$(CONFIG_ARGS) N_CORES=$(N_CORES)

example_CLI :
	CLI_build/cogaps --data Standalone_CLI/data/GIST.mtx --nIterations 5000 --nCores $(N_CORES)

valgrind_CLI :
	valgrind CLI_build/cogaps --data SampleData/GIST.mtx --nIterations 5000 --nCores $(N_CORES)

helgrind_CLI :
	valgrind --tool=helgrind CLI_build/cogaps --data SampleData/GIST.mtx --nIterations 5000 --nCores $(N_CORES)

profile_CLI :
	mkdir -p profiles
	mkdir -p profiles/CLI
	valgrind --tool=callgrind CLI_build/cogaps --data SampleData/GIST.mtx --nIterations 2500
	mv callgrind.out.* profiles/CLI

## Targets for Python Package

install_py :
	pip3 install ./Python_Package
	
example_py :
	python3 -c 'import cogaps; cogaps.runCogaps("Python_Package/data/GIST.csv")'

## Profiling/Benchmarking Targets

profile_R_square :
	mkdir -p profiles
	mkdir -p profiles/R
	R -d "valgrind --tool=callgrind" -e 'library(CoGAPS); data(GIST); data <- matrix(sample(GIST.matrix, size=250*250, replace=TRUE), nrow=250); CoGAPS(data, nIterations=2000, outputFrequency=250)'
	mv callgrind.out.* profiles/R

profile_R_rectangle :
	mkdir -p profiles
	mkdir -p profiles/R
	R -d "valgrind --tool=callgrind" -e 'library(CoGAPS); data(GIST); set.seed(123); data <- matrix(sample(GIST.matrix, size=20*10000, replace=TRUE), nrow=20); CoGAPS(data, nIterations=2500, outputFrequency=250, seed=123)'
	mv callgrind.out.* profiles/R

perf_R_square :
	perf record R -e 'library(CoGAPS); data(GIST); data <- matrix(sample(GIST.matrix, size=500*500, replace=TRUE), nrow=500); CoGAPS(data, nIterations=5000, outputFrequency=1000)'
	perf report --stdio

perf_R_rectangle :
	perf record R -e 'library(CoGAPS); data(GIST); set.seed(123); data <- matrix(sample(GIST.matrix, size=20*10000, replace=TRUE), nrow=20); CoGAPS(data, nIterations=2500, outputFrequency=500, seed=123)'
	perf report --stdio

PERF_CACHE_STATS=L1-dcache-loads,L1-dcache-load-misses,L1-icache-loads,L1-icache-load-misses,cache-references,cache-misses,LLC-loads,LLC-load-misses
PERF_STATS=$(PERF_CACHE_STATS),cycles,instructions,branches,branch-misses,faults,migrations,stalled-cycles-frontend

perf_stat_R_rectangle :
	perf stat -B -e $(PERF_STATS) R -e 'library(CoGAPS); data(GIST); set.seed(123); data <- matrix(sample(GIST.matrix, size=20*10000, replace=TRUE), nrow=20); CoGAPS(data, nIterations=1000, outputFrequency=500, seed=123)'

benchmark_R_rectangle :
	/usr/bin/time -v R -e 'library(CoGAPS); data(GIST); set.seed(123); data <- matrix(sample(GIST.matrix, size=20*10000, replace=TRUE), nrow=20); CoGAPS(data, nIterations=2500, outputFrequency=500, seed=123)'

benchmark_R_square :
	/usr/bin/time -v R -e 'library(CoGAPS); data(GIST); data <- matrix(sample(GIST.matrix, size=250*250, replace=TRUE), nrow=250); CoGAPS(data, nIterations=5000, outputFrequency=1000)'

## Miscellaneous Targets

build_and_install_valgrind :
	cd external && \
	tar -xf valgrind-3.15.0.patched.tar.bz2 && \
	cd valgrind-3.15.0 && \
	./autogen.sh && \
	./configure && \
	make && \
	make install && \
	cd .. && \
	rm -rf valgrind-3.15.0
	
## Help targets

help :
	@echo "make help_R..........R package specific help message"
	@echo "make help_CLI........standalone CLI specific help message"

help_R :
	@echo "make install_R.......................install CoGAPS R package"
	@echo "make R_configure_script..............run configure.ac through autoreconf"
	@echo "make build_R.........................build the package tarball"
	@echo "make build_R_with_vignettes..........build the package tarball with vignettes"
	@echo "make vignette........................render vignette pdf/html"
	@echo "make docs_R..........................generate documentation files"
	@echo "make RcppInterface...................generate RcppExports R and C++ file"
	@echo "make test_R_package..................run unit tests"
	@echo "make check_R_package.................run Bioconductor package checks"
	@echo "make example_R.......................run short CoGAPS example"
	@echo "make example_R_from_file.............run short CoGAPS example with file input"
	@echo "make set_R_compiler_gcc..............set the R compiler to gcc"
	@echo "make set_R_compiler_clang............set the R compiler to clang"
	@echo "make install_R_debug.................install the debug version of CoGAPS "
	@echo "make install_R_with_warnings.........install CoGAPS with compiler warnings enabled"
	@echo "make test_R_install..................test installation success"
	@echo "make test_R_gcc_install..............test installation success for gcc"
	@echo "make test_R_clang_install............test installation success for clang"
	@echo "make lint_R..........................lint R code"
	@echo "make lint_R_Package_cpp..............lint C++ code in R package"
	@echo "make lint_R_Package_cpp_with_errors..lint C++ code with failure on warnings"
	@echo "make lint_R_Package..................lint all code in R package"
	@echo "make full_R_test_suite...............run R package through all available tests"
