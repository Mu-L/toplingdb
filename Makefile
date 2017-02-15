# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

# Inherit some settings from environment variables, if available

#-----------------------------------------------
BMI2 ?= 0

COMPILER=$(shell t=`mktemp --suffix=.exe`; ${CXX} terark-tools/detect-compiler.cpp -o $$t && $$t && rm -f $$t)
UNAME_MachineSystem=$(shell uname -m -s | sed 's:[ /]:-:g')
TerocksDir=../terark-zip-rocksdb/pkg/terark-zip-rocksdb${TerocksTrial}-${UNAME_MachineSystem}-${COMPILER}-bmi2-${BMI2}
export LD_LIBRARY_PATH:=${TerocksDir}/lib:${LD_LIBRARY_PATH}

EXTRA_CXXFLAGS += -I../terark-zip-rocksdb/src
BASH_EXISTS := $(shell which bash)
SHELL := $(shell which bash)

CLEAN_FILES = # deliberately empty, so we can append below.
CFLAGS += ${EXTRA_CFLAGS}
CXXFLAGS += ${EXTRA_CXXFLAGS}
LDFLAGS += $(EXTRA_LDFLAGS)
MACHINE ?= $(shell uname -m)
ARFLAGS = rs

# Transform parallel LOG output into something more readable.
perl_command = perl -n \
  -e '@a=split("\t",$$_,-1); $$t=$$a[8];'				\
  -e '$$t =~ /.*if\s\[\[\s"(.*?\.[\w\/]+)/ and $$t=$$1;'		\
  -e '$$t =~ s,^\./,,;'							\
  -e '$$t =~ s, >.*,,; chomp $$t;'					\
  -e '$$t =~ /.*--gtest_filter=(.*?\.[\w\/]+)/ and $$t=$$1;'		\
  -e 'printf "%7.3f %s %s\n", $$a[3], $$a[6] == 0 ? "PASS" : "FAIL", $$t'
quoted_perl_command = $(subst ','\'',$(perl_command))

# DEBUG_LEVEL can have three values:
# * DEBUG_LEVEL=2; this is the ultimate debug mode. It will compile rocksdb
# without any optimizations. To compile with level 2, issue `make dbg`
# * DEBUG_LEVEL=1; debug level 1 enables all assertions and debug code, but
# compiles rocksdb with -O2 optimizations. this is the default debug level.
# `make all` or `make <binary_target>` compile RocksDB with debug level 1.
# We use this debug level when developing RocksDB.
# * DEBUG_LEVEL=0; this is the debug level we use for release. If you're
# running rocksdb in production you most definitely want to compile RocksDB
# with debug level 0. To compile with level 0, run `make shared_lib`,
# `make install-shared`, `make static_lib`, `make install-static` or
# `make install`

# Set the default DEBUG_LEVEL to 1
DEBUG_LEVEL?=2

ifeq ($(MAKECMDGOALS),dbg)
	DEBUG_LEVEL=2
endif

ifeq ($(MAKECMDGOALS),clean)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),release)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),shared_lib)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install-shared)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),static_lib)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install-static)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),install)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),rocksdbjavastatic)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),rocksdbjavastaticrelease)
	DEBUG_LEVEL=0
endif

ifeq ($(MAKECMDGOALS),rocksdbjavastaticpublish)
	DEBUG_LEVEL=0
endif

ifeq (${DEBUG_LEVEL}, 0)
  DBG_OR_RLS=r
else
  DBG_OR_RLS=d
endif
ifeq ("$(LINK_STATIC_TERARK)","")
  TerocksLDFLAGS += -L${TerocksDir}/lib \
                    -lterark-zip-rocksdb-${DBG_OR_RLS} \
                    -lterark-zbs-${DBG_OR_RLS} \
                    -lterark-fsa-${DBG_OR_RLS} \
                    -lterark-core-${DBG_OR_RLS}
else
  TerarkBuild = ../terark/build/${UNAME_MachineSystem}-${COMPILER}-bmi2-${BMI2}
  override LINK_STATIC_TERARK = \
    ${TerocksDir}/lib_static/libterark-zip-rocksdb${TerocksTrial}-${DBG_OR_RLS}.a \
    ${TerarkBuild}/lib/libterark-zbs-${DBG_OR_RLS}.a \
    ${TerarkBuild}/lib/libterark-fsa-${DBG_OR_RLS}.a \
    ${TerarkBuild}/lib/libterark-core-${DBG_OR_RLS}.a
endif

# compile with -O2 if debug level is not 2
ifneq ($(DEBUG_LEVEL), 2)
OPT += -O2 -fno-omit-frame-pointer
# Skip for archs that don't support -momit-leaf-frame-pointer
ifeq (,$(shell $(CXX) -fsyntax-only -momit-leaf-frame-pointer -xc /dev/null 2>&1))
OPT += -momit-leaf-frame-pointer
endif
endif

# if we're compiling for release, compile without debug code (-DNDEBUG) and
# don't treat warnings as errors
ifeq ($(DEBUG_LEVEL),0)
OPT += -DNDEBUG
DISABLE_WARNING_AS_ERROR=1
else
$(warning Warning: Compiling in debug mode. Don't use the resulting binary in production)
endif

#-----------------------------------------------
include src.mk

AM_DEFAULT_VERBOSITY = 1

AM_V_GEN = $(am__v_GEN_$(V))
am__v_GEN_ = $(am__v_GEN_$(AM_DEFAULT_VERBOSITY))
am__v_GEN_0 = @echo "  GEN     " $@;
am__v_GEN_1 =
AM_V_at = $(am__v_at_$(V))
am__v_at_ = $(am__v_at_$(AM_DEFAULT_VERBOSITY))
am__v_at_0 = @
am__v_at_1 =

AM_V_CC = $(am__v_CC_$(V))
am__v_CC_ = $(am__v_CC_$(AM_DEFAULT_VERBOSITY))
am__v_CC_0 = @echo "  CC      " $@;
am__v_CC_1 =
CCLD = $(CC)
LINK = $(CCLD) $(AM_CFLAGS) $(CFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@
AM_V_CCLD = $(am__v_CCLD_$(V))
am__v_CCLD_ = $(am__v_CCLD_$(AM_DEFAULT_VERBOSITY))
am__v_CCLD_0 = @echo "  CCLD    " $@;
am__v_CCLD_1 =
AM_V_AR = $(am__v_AR_$(V))
am__v_AR_ = $(am__v_AR_$(AM_DEFAULT_VERBOSITY))
am__v_AR_0 = @echo "  AR      " $@;
am__v_AR_1 =

ifdef ROCKSDB_USE_LIBRADOS
LIB_SOURCES += utilities/env_librados.cc
LDFLAGS += -lrados
endif

AM_LINK = $(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ ${TerocksLDFLAGS} $(LDFLAGS) $(COVERAGEFLAGS)
# detect what platform we're building on
dummy := $(shell (export ROCKSDB_ROOT="$(CURDIR)"; export PORTABLE="$(PORTABLE)"; "$(CURDIR)/build_tools/build_detect_platform" "$(CURDIR)/make_config.mk"))
# this file is generated by the previous line to set build flags and sources
include make_config.mk
CLEAN_FILES += make_config.mk

missing_make_config_paths := $(shell				\
	grep "\/\S*" -o $(CURDIR)/make_config.mk | 		\
	while read path;					\
		do [ -e $$path ] || echo $$path; 		\
	done | sort | uniq)

$(foreach path, $(missing_make_config_paths), \
	$(warning Warning: $(path) dont exist))

ifneq ($(PLATFORM), IOS)
CFLAGS += -g
CXXFLAGS += -g
else
# no debug info for IOS, that will make our library big
OPT += -DNDEBUG
endif

ifeq ($(PLATFORM), OS_SOLARIS)
	PLATFORM_CXXFLAGS += -D _GLIBCXX_USE_C99
endif
ifneq ($(filter -DROCKSDB_LITE,$(OPT)),)
	# found
	CFLAGS += -fno-exceptions
	CXXFLAGS += -fno-exceptions
	# LUA is not supported under ROCKSDB_LITE
	LUA_PATH =
endif

# ASAN doesn't work well with jemalloc. If we're compiling with ASAN, we should use regular malloc.
ifdef COMPILE_WITH_ASAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=address
	PLATFORM_CCFLAGS += -fsanitize=address
	PLATFORM_CXXFLAGS += -fsanitize=address
endif

# TSAN doesn't work well with jemalloc. If we're compiling with TSAN, we should use regular malloc.
ifdef COMPILE_WITH_TSAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=thread -pie
	PLATFORM_CCFLAGS += -fsanitize=thread -fPIC -DROCKSDB_TSAN_RUN
	PLATFORM_CXXFLAGS += -fsanitize=thread -fPIC -DROCKSDB_TSAN_RUN
        # Turn off -pg when enabling TSAN testing, because that induces
        # a link failure.  TODO: find the root cause
	PROFILING_FLAGS =
	# LUA is not supported under TSAN
	LUA_PATH =
endif

# USAN doesn't work well with jemalloc. If we're compiling with USAN, we should use regular malloc.
ifdef COMPILE_WITH_UBSAN
	DISABLE_JEMALLOC=1
	EXEC_LDFLAGS += -fsanitize=undefined
	PLATFORM_CCFLAGS += -fsanitize=undefined
	PLATFORM_CXXFLAGS += -fsanitize=undefined
endif

ifndef DISABLE_JEMALLOC
	ifdef JEMALLOC
		PLATFORM_CXXFLAGS += "-DROCKSDB_JEMALLOC"
		PLATFORM_CCFLAGS +=  "-DROCKSDB_JEMALLOC"
	endif
	EXEC_LDFLAGS := $(JEMALLOC_LIB) $(EXEC_LDFLAGS)
	PLATFORM_CXXFLAGS += $(JEMALLOC_INCLUDE)
	PLATFORM_CCFLAGS += $(JEMALLOC_INCLUDE)
endif

export GTEST_THROW_ON_FAILURE=1 GTEST_HAS_EXCEPTIONS=1
GTEST_DIR = ./third-party/gtest-1.7.0/fused-src
PLATFORM_CCFLAGS += -isystem $(GTEST_DIR)
PLATFORM_CXXFLAGS += -isystem $(GTEST_DIR)

# This (the first rule) must depend on "all".
default: all

WARNING_FLAGS = -W -Wextra -Wall -Wsign-compare -Wshadow \
  -Wno-unused-parameter

ifndef DISABLE_WARNING_AS_ERROR
	WARNING_FLAGS += -Werror
endif


ifdef LUA_PATH

ifndef LUA_INCLUDE
LUA_INCLUDE=$(LUA_PATH)/include
endif

LUA_INCLUDE_FILE=$(LUA_INCLUDE)/lualib.h

ifeq ("$(wildcard $(LUA_INCLUDE_FILE))", "")
# LUA_INCLUDE_FILE does not exist
$(error Cannot find lualib.h under $(LUA_INCLUDE).  Try to specify both LUA_PATH and LUA_INCLUDE manually)
endif
LUA_FLAGS = -I$(LUA_INCLUDE) -DLUA -DLUA_COMPAT_ALL
CFLAGS += $(LUA_FLAGS)
CXXFLAGS += $(LUA_FLAGS)

ifndef LUA_LIB
LUA_LIB = $(LUA_PATH)/lib/liblua.a
endif
ifeq ("$(wildcard $(LUA_LIB))", "") # LUA_LIB does not exist
$(error $(LUA_LIB) does not exist.  Try to specify both LUA_PATH and LUA_LIB manually)
endif
LDFLAGS += $(LUA_LIB)

endif


CFLAGS += $(WARNING_FLAGS) -I. -I./include $(PLATFORM_CCFLAGS) $(OPT)
CXXFLAGS += $(WARNING_FLAGS) -I. -I./include $(PLATFORM_CXXFLAGS) $(OPT) -Woverloaded-virtual -Wnon-virtual-dtor -Wno-missing-field-initializers

LDFLAGS += $(PLATFORM_LDFLAGS)

date := $(shell date +%F)
ifdef FORCE_GIT_SHA
	git_sha := $(FORCE_GIT_SHA)
else
	git_sha := $(shell git rev-parse HEAD 2>/dev/null)
endif
gen_build_version = sed -e s/@@GIT_SHA@@/$(git_sha)/ -e s/@@GIT_DATE_TIME@@/$(date)/ util/build_version.cc.in

# Record the version of the source that we are compiling.
# We keep a record of the git revision in this file.  It is then built
# as a regular source file as part of the compilation process.
# One can run "strings executable_filename | grep _build_" to find
# the version of the source that we used to build the executable file.
CLEAN_FILES += util/build_version.cc:
FORCE:
util/build_version.cc: FORCE
	$(AM_V_GEN)rm -f $@-t
	$(AM_V_at)$(gen_build_version) > $@-t
	$(AM_V_at)if test -f $@; then					\
	  cmp -s $@-t $@ && rm -f $@-t || mv -f $@-t $@;		\
	else mv -f $@-t $@; fi

LIBOBJECTS = $(LIB_SOURCES:.cc=.o)
LIBOBJECTS += $(TOOL_LIB_SOURCES:.cc=.o)
MOCKOBJECTS = $(MOCK_LIB_SOURCES:.cc=.o)

GTEST = $(GTEST_DIR)/gtest/gtest-all.o
TESTUTIL = ./util/testutil.o
TESTHARNESS = ./util/testharness.o $(TESTUTIL) $(MOCKOBJECTS) $(GTEST)
VALGRIND_ERROR = 2
VALGRIND_VER := $(join $(VALGRIND_VER),valgrind)

VALGRIND_OPTS = --error-exitcode=$(VALGRIND_ERROR) --leak-check=full

BENCHTOOLOBJECTS = $(BENCH_LIB_SOURCES:.cc=.o) $(LIBOBJECTS) $(TESTUTIL)

EXPOBJECTS = $(EXP_LIB_SOURCES:.cc=.o) $(LIBOBJECTS) $(TESTUTIL)

TESTS = \
	db_test \
	db_test2 \
	db_block_cache_test \
	db_bloom_filter_test \
	db_iter_test \
	db_log_iter_test \
	db_compaction_filter_test \
	db_compaction_test \
	db_dynamic_level_test \
	db_flush_test \
	db_inplace_update_test \
	db_iterator_test \
	db_memtable_test \
	db_merge_operator_test \
	db_options_test \
	db_range_del_test \
	db_sst_test \
	external_sst_file_test \
	db_tailing_iter_test \
	db_universal_compaction_test \
	db_wal_test \
	db_io_failure_test \
	db_properties_test \
	db_table_properties_test \
	autovector_test \
	cleanable_test \
	column_family_test \
	table_properties_collector_test \
	arena_test \
	auto_roll_logger_test \
	block_test \
	bloom_test \
	dynamic_bloom_test \
	c_test \
	cache_test \
	checkpoint_test \
	coding_test \
	corruption_test \
	crc32c_test \
	slice_transform_test \
	dbformat_test \
	env_basic_test \
	env_test \
	fault_injection_test \
	filelock_test \
	filename_test \
	file_reader_writer_test \
	block_based_filter_block_test \
	full_filter_block_test \
	hash_table_test \
	histogram_test \
	inlineskiplist_test \
	log_test \
	manual_compaction_test \
	mock_env_test \
	memtable_list_test \
	merge_helper_test \
	memory_test \
	merge_test \
	merger_test \
	util_merge_operators_test \
	options_file_test \
	redis_test \
	reduce_levels_test \
	plain_table_db_test \
	comparator_db_test \
	prefix_test \
	skiplist_test \
	stringappend_test \
	ttl_test \
	date_tiered_test \
	backupable_db_test \
	blob_db_test \
	document_db_test \
	json_document_test \
	sim_cache_test \
	spatial_db_test \
	version_edit_test \
	version_set_test \
	compaction_picker_test \
	version_builder_test \
	file_indexer_test \
	write_batch_test \
	write_batch_with_index_test \
	write_controller_test\
	deletefile_test \
	table_test \
	thread_local_test \
	geodb_test \
	rate_limiter_test \
	delete_scheduler_test \
	options_test \
	options_settable_test \
	options_util_test \
	event_logger_test \
	cuckoo_table_builder_test \
	cuckoo_table_reader_test \
	cuckoo_table_db_test \
	flush_job_test \
	wal_manager_test \
	listener_test \
	compaction_iterator_test \
	compaction_job_test \
	thread_list_test \
	sst_dump_test \
	column_aware_encoding_test \
	compact_files_test \
	perf_context_test \
	optimistic_transaction_test \
	write_callback_test \
	compact_on_deletion_collector_test \
	compaction_job_stats_test \
	option_change_migration_test \
	transaction_test \
	ldb_cmd_test \
	iostats_context_test \
	persistent_cache_test \
	statistics_test \
	lua_test \
	range_del_aggregator_test \
	lru_cache_test \
	terark_zip_table_db_test \
	terark_zip_table_reader_test \

PARALLEL_TEST = \
	backupable_db_test \
	db_compaction_filter_test \
	db_compaction_test \
	db_sst_test \
	db_test \
	db_universal_compaction_test \
	db_wal_test \
	external_sst_file_test \
	fault_injection_test \
	inlineskiplist_test \
	manual_compaction_test \
	persistent_cache_test \
	table_test \
	transaction_test

SUBSET := $(TESTS)
ifdef ROCKSDBTESTS_START
        SUBSET := $(shell echo $(SUBSET) | sed 's/^.*$(ROCKSDBTESTS_START)/$(ROCKSDBTESTS_START)/')
endif

ifdef ROCKSDBTESTS_END
        SUBSET := $(shell echo $(SUBSET) | sed 's/$(ROCKSDBTESTS_END).*//')
endif

TOOLS = \
	sst_dump \
	db_sanity_test \
	db_stress \
	write_stress \
	ldb \
	db_repl_stress \
	rocksdb_dump \
	rocksdb_undump

TEST_LIBS = \
	librocksdb_env_basic_test.a

# TODO: add back forward_iterator_bench, after making it build in all environemnts.
BENCHMARKS = db_bench table_reader_bench cache_bench memtablerep_bench column_aware_encoding_exp persistent_cache_bench

# if user didn't config LIBNAME, set the default
ifeq ($(LIBNAME),)
# we should only run rocksdb in production with DEBUG_LEVEL 0
ifeq ($(DEBUG_LEVEL),0)
        LIBNAME=librocksdb
else
        LIBNAME=librocksdb_debug
endif
endif
LIBRARY = ${LIBNAME}.a
TOOLS_LIBRARY = ${LIBNAME}_tools.a

ROCKSDB_MAJOR = $(shell egrep "ROCKSDB_MAJOR.[0-9]" include/rocksdb/version.h | cut -d ' ' -f 3)
ROCKSDB_MINOR = $(shell egrep "ROCKSDB_MINOR.[0-9]" include/rocksdb/version.h | cut -d ' ' -f 3)
ROCKSDB_PATCH = $(shell egrep "ROCKSDB_PATCH.[0-9]" include/rocksdb/version.h | cut -d ' ' -f 3)

default: all

#-----------------------------------------------
# Create platform independent shared libraries.
#-----------------------------------------------
ifneq ($(PLATFORM_SHARED_EXT),)

ifneq ($(PLATFORM_SHARED_VERSIONED),true)
SHARED1 = ${LIBNAME}.$(PLATFORM_SHARED_EXT)
SHARED2 = $(SHARED1)
SHARED3 = $(SHARED1)
SHARED4 = $(SHARED1)
SHARED = $(SHARED1)
else
SHARED_MAJOR = $(ROCKSDB_MAJOR)
SHARED_MINOR = $(ROCKSDB_MINOR)
SHARED_PATCH = $(ROCKSDB_PATCH)
SHARED1 = ${LIBNAME}.$(PLATFORM_SHARED_EXT)
ifeq ($(PLATFORM), OS_MACOSX)
SHARED_OSX = $(LIBNAME).$(SHARED_MAJOR)
SHARED2 = $(SHARED_OSX).$(PLATFORM_SHARED_EXT)
SHARED3 = $(SHARED_OSX).$(SHARED_MINOR).$(PLATFORM_SHARED_EXT)
SHARED4 = $(SHARED_OSX).$(SHARED_MINOR).$(SHARED_PATCH).$(PLATFORM_SHARED_EXT)
else
SHARED2 = $(SHARED1).$(SHARED_MAJOR)
SHARED3 = $(SHARED1).$(SHARED_MAJOR).$(SHARED_MINOR)
SHARED4 = $(SHARED1).$(SHARED_MAJOR).$(SHARED_MINOR).$(SHARED_PATCH)
endif
SHARED = $(SHARED1) $(SHARED2) $(SHARED3) $(SHARED4)
$(SHARED1): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED1)
$(SHARED2): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED2)
$(SHARED3): $(SHARED4)
	ln -fs $(SHARED4) $(SHARED3)
endif

$(SHARED4):
	$(CXX) $(PLATFORM_SHARED_LDFLAGS)$(SHARED3) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) $(LIB_SOURCES) $(TOOL_LIB_SOURCES) \
		$(LDFLAGS) $(LINK_STATIC_TERARK) -o $@

endif  # PLATFORM_SHARED_EXT

.PHONY: blackbox_crash_test check clean coverage crash_test ldb_tests package \
	release tags valgrind_check whitebox_crash_test format static_lib shared_lib all \
	dbg rocksdbjavastatic rocksdbjava install install-static install-shared uninstall \
	analyze tools tools_lib


all: $(LIBRARY) $(BENCHMARKS) tools tools_lib test_libs $(TESTS)

static_lib: $(LIBRARY)

shared_lib: $(SHARED)

tools: $(TOOLS)

tools_lib: $(TOOLS_LIBRARY)

test_libs: $(TEST_LIBS)

dbg: $(LIBRARY) $(BENCHMARKS) tools $(TESTS)

# creates static library and programs
release:
	#$(MAKE) clean
	DEBUG_LEVEL=0 $(MAKE) static_lib tools db_bench

coverage:
	$(MAKE) clean
	COVERAGEFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS+="-lgcov" $(MAKE) J=1 all check
	cd coverage && ./coverage_test.sh
        # Delete intermediate files
	find . -type f -regex ".*\.\(\(gcda\)\|\(gcno\)\)" -exec rm {} \;

ifneq (,$(filter check parallel_check,$(MAKECMDGOALS)),)
# Use /dev/shm if it has the sticky bit set (otherwise, /tmp),
# and create a randomly-named rocksdb.XXXX directory therein.
# We'll use that directory in the "make check" rules.
ifeq ($(TMPD),)
TMPD := $(shell f=/dev/shm; test -k $$f || f=/tmp;			\
  perl -le 'use File::Temp "tempdir";'					\
    -e 'print tempdir("'$$f'/rocksdb.XXXX", CLEANUP => 0)')
endif
endif

# Run all tests in parallel, accumulating per-test logs in t/log-*.
#
# Each t/run-* file is a tiny generated bourne shell script that invokes one of
# sub-tests. Why use a file for this?  Because that makes the invocation of
# parallel below simpler, which in turn makes the parsing of parallel's
# LOG simpler (the latter is for live monitoring as parallel
# tests run).
#
# Test names are extracted by running tests with --gtest_list_tests.
# This filter removes the "#"-introduced comments, and expands to
# fully-qualified names by changing input like this:
#
#   DBTest.
#     Empty
#     WriteEmptyBatch
#   MultiThreaded/MultiThreadedDBTest.
#     MultiThreaded/0  # GetParam() = 0
#     MultiThreaded/1  # GetParam() = 1
#
# into this:
#
#   DBTest.Empty
#   DBTest.WriteEmptyBatch
#   MultiThreaded/MultiThreadedDBTest.MultiThreaded/0
#   MultiThreaded/MultiThreadedDBTest.MultiThreaded/1
#

parallel_tests = $(patsubst %,parallel_%,$(PARALLEL_TEST))
.PHONY: gen_parallel_tests $(parallel_tests)
$(parallel_tests): $(PARALLEL_TEST)
	$(AM_V_at)TEST_BINARY=$(patsubst parallel_%,%,$@); \
  TEST_NAMES=` \
    ./$$TEST_BINARY --gtest_list_tests \
    | perl -n \
      -e 's/ *\#.*//;' \
      -e '/^(\s*)(\S+)/; !$$1 and do {$$p=$$2; break};'	\
      -e 'print qq! $$p$$2!'`; \
	for TEST_NAME in $$TEST_NAMES; do \
		TEST_SCRIPT=t/run-$$TEST_BINARY-$${TEST_NAME//\//-}; \
		echo "  GEN     " $$TEST_SCRIPT; \
    printf '%s\n' \
      '#!/bin/sh' \
      "d=\$(TMPD)$$TEST_SCRIPT" \
      'mkdir -p $$d' \
      "TEST_TMPDIR=\$$d $(DRIVER) ./$$TEST_BINARY --gtest_filter=$$TEST_NAME" \
		> $$TEST_SCRIPT; \
		chmod a=rx $$TEST_SCRIPT; \
	done

gen_parallel_tests:
	$(AM_V_at)mkdir -p t
	$(AM_V_at)rm -f t/run-*
	$(MAKE) $(parallel_tests)

# Reorder input lines (which are one per test) so that the
# longest-running tests appear first in the output.
# Do this by prefixing each selected name with its duration,
# sort the resulting names, and remove the leading numbers.
# FIXME: the "100" we prepend is a fake time, for now.
# FIXME: squirrel away timings from each run and use them
# (when present) on subsequent runs to order these tests.
#
# Without this reordering, these two tests would happen to start only
# after almost all other tests had completed, thus adding 100 seconds
# to the duration of parallel "make check".  That's the difference
# between 4 minutes (old) and 2m20s (new).
#
# 152.120 PASS t/DBTest.FileCreationRandomFailure
# 107.816 PASS t/DBTest.EncodeDecompressedBlockSizeTest
#
slow_test_regexp = \
	^t/run-table_test-HarnessTest.Randomized$$|^t/run-db_test-.*(?:FileCreationRandomFailure|EncodeDecompressedBlockSizeTest)$$|^.*RecoverFromCorruptedWALWithoutFlush$$
prioritize_long_running_tests =						\
  perl -pe 's,($(slow_test_regexp)),100 $$1,'				\
    | sort -k1,1gr							\
    | sed 's/^[.0-9]* //'

# "make check" uses
# Run with "make J=1 check" to disable parallelism in "make check".
# Run with "make J=200% check" to run two parallel jobs per core.
# The default is to run one job per core (J=100%).
# See "man parallel" for its "-j ..." option.
J ?= 100%

# Use this regexp to select the subset of tests whose names match.
tests-regexp = .

t_run = $(wildcard t/run-*)
.PHONY: check_0
check_0:
	$(AM_V_GEN)export TEST_TMPDIR=$(TMPD); \
	printf '%s\n' ''						\
	  'To monitor subtest <duration,pass/fail,name>,'		\
	  '  run "make watch-log" in a separate window' '';		\
	test -t 1 && eta=--eta || eta=; \
	{ \
		printf './%s\n' $(filter-out $(PARALLEL_TEST),$(TESTS)); \
		printf '%s\n' $(t_run); \
	} \
	  | $(prioritize_long_running_tests)				\
	  | grep -E '$(tests-regexp)'					\
	  | build_tools/gnu_parallel -j$(J) --plain --joblog=LOG $$eta --gnu '{} >& t/log-{/}'

.PHONY: valgrind_check_0
valgrind_check_0:
	$(AM_V_GEN)export TEST_TMPDIR=$(TMPD);				\
	printf '%s\n' ''						\
	  'To monitor subtest <duration,pass/fail,name>,'		\
	  '  run "make watch-log" in a separate window' '';		\
	test -t 1 && eta=--eta || eta=;					\
	{								\
	  printf './%s\n' $(filter-out $(PARALLEL_TEST) %skiplist_test options_settable_test, $(TESTS));		\
	  printf '%s\n' $(t_run);					\
	}								\
	  | $(prioritize_long_running_tests)				\
	  | grep -E '$(tests-regexp)'					\
	  | build_tools/gnu_parallel -j$(J) --plain --joblog=LOG $$eta --gnu \
	  '(if [[ "{}" == "./"* ]] ; then $(DRIVER) {}; else {}; fi) ' \
	  '>& t/valgrind_log-{/}'

CLEAN_FILES += t LOG $(TMPD)

# When running parallel "make check", you can monitor its progress
# from another window.
# Run "make watch_LOG" to show the duration,PASS/FAIL,name of parallel
# tests as they are being run.  We sort them so that longer-running ones
# appear at the top of the list and any failing tests remain at the top
# regardless of their duration. As with any use of "watch", hit ^C to
# interrupt.
watch-log:
	watch --interval=0 'sort -k7,7nr -k4,4gr LOG|$(quoted_perl_command)'

# If J != 1 and GNU parallel is installed, run the tests in parallel,
# via the check_0 rule above.  Otherwise, run them sequentially.
check: all
	$(MAKE) gen_parallel_tests
	$(AM_V_GEN)if test "$(J)" != 1                                  \
	    && (build_tools/gnu_parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
	    $(MAKE) T="$$t" TMPD=$(TMPD) check_0;                       \
	else                                                            \
	    for t in $(TESTS); do                                       \
	      echo "===== Running $$t"; ./$$t || exit 1; done;          \
	fi
	rm -rf $(TMPD)
ifeq ($(filter -DROCKSDB_LITE,$(OPT)),)
	python tools/ldb_test.py
	sh tools/rocksdb_dump_test.sh
endif

# TODO add ldb_tests
check_some: $(SUBSET)
	for t in $(SUBSET); do echo "===== Running $$t"; ./$$t || exit 1; done

.PHONY: ldb_tests
ldb_tests: ldb
	python tools/ldb_test.py

crash_test: whitebox_crash_test blackbox_crash_test

blackbox_crash_test: db_stress
	python -u tools/db_crashtest.py --simple blackbox
	python -u tools/db_crashtest.py blackbox

ifeq ($(CRASH_TEST_KILL_ODD),)
  CRASH_TEST_KILL_ODD=888887
endif

whitebox_crash_test: db_stress
	python -u tools/db_crashtest.py --simple whitebox --random_kill_odd \
      $(CRASH_TEST_KILL_ODD)
	python -u tools/db_crashtest.py whitebox  --random_kill_odd \
      $(CRASH_TEST_KILL_ODD)

asan_check:
	$(MAKE) clean
	COMPILE_WITH_ASAN=1 $(MAKE) check -j32
	$(MAKE) clean

asan_crash_test:
	$(MAKE) clean
	COMPILE_WITH_ASAN=1 $(MAKE) crash_test
	$(MAKE) clean

ubsan_check:
	$(MAKE) clean
	COMPILE_WITH_UBSAN=1 $(MAKE) check -j32
	$(MAKE) clean

ubsan_crash_test:
	$(MAKE) clean
	COMPILE_WITH_UBSAN=1 $(MAKE) crash_test
	$(MAKE) clean

valgrind_test:
	DISABLE_JEMALLOC=1 $(MAKE) valgrind_check

valgrind_check: $(TESTS)
	$(MAKE) DRIVER="$(VALGRIND_VER) $(VALGRIND_OPTS)" gen_parallel_tests
	$(AM_V_GEN)if test "$(J)" != 1                                  \
	    && (build_tools/gnu_parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
      $(MAKE) TMPD=$(TMPD)                                        \
      DRIVER="$(VALGRIND_VER) $(VALGRIND_OPTS)" valgrind_check_0; \
	else                                                            \
		for t in $(filter-out %skiplist_test options_settable_test,$(TESTS)); do \
			$(VALGRIND_VER) $(VALGRIND_OPTS) ./$$t; \
			ret_code=$$?; \
			if [ $$ret_code -ne 0 ]; then \
				exit $$ret_code; \
			fi; \
		done; \
	fi


ifneq ($(PAR_TEST),)
parloop:
	ret_bad=0;							\
	for t in $(PAR_TEST); do		\
		echo "===== Running $$t in parallel $(NUM_PAR)";\
		if [ $(db_test) -eq 1 ]; then \
			seq $(J) | v="$$t" build_tools/gnu_parallel --gnu --plain 's=$(TMPD)/rdb-{};  export TEST_TMPDIR=$$s;' \
				'timeout 2m ./db_test --gtest_filter=$$v >> $$s/log-{} 2>1'; \
		else\
			seq $(J) | v="./$$t" build_tools/gnu_parallel --gnu --plain 's=$(TMPD)/rdb-{};' \
			     'export TEST_TMPDIR=$$s; timeout 10m $$v >> $$s/log-{} 2>1'; \
		fi; \
		ret_code=$$?; \
		if [ $$ret_code -ne 0 ]; then \
			ret_bad=$$ret_code; \
			echo $$t exited with $$ret_code; \
		fi; \
	done; \
	exit $$ret_bad;
endif

test_names = \
  ./db_test --gtest_list_tests						\
    | perl -n								\
      -e 's/ *\#.*//;'							\
      -e '/^(\s*)(\S+)/; !$$1 and do {$$p=$$2; break};'			\
      -e 'print qq! $$p$$2!'

parallel_check: $(TESTS)
	$(AM_V_GEN)if test "$(J)" > 1                                  \
	    && (build_tools/gnu_parallel --gnu --help 2>/dev/null) |                    \
	        grep -q 'GNU Parallel';                                 \
	then                                                            \
	    echo Running in parallel $(J);			\
	else                                                            \
	    echo "Need to have GNU Parallel and J > 1"; exit 1;		\
	fi;								\
	ret_bad=0;							\
	echo $(J);\
	echo Test Dir: $(TMPD); \
        seq $(J) | build_tools/gnu_parallel --gnu --plain 's=$(TMPD)/rdb-{}; rm -rf $$s; mkdir $$s'; \
	$(MAKE)  PAR_TEST="$(shell $(test_names))" TMPD=$(TMPD) \
		J=$(J) db_test=1 parloop; \
	$(MAKE) PAR_TEST="$(filter-out db_test, $(TESTS))" \
		TMPD=$(TMPD) J=$(J) db_test=0 parloop;

analyze: clean
	$(CLANG_SCAN_BUILD) --use-analyzer=$(CLANG_ANALYZER) \
		--use-c++=$(CXX) --use-cc=$(CC) --status-bugs \
		-o $(CURDIR)/scan_build_report \
		$(MAKE) dbg

CLEAN_FILES += unity.cc
unity.cc: Makefile
	rm -f $@ $@-t
	for source_file in $(LIB_SOURCES); do \
		echo "#include \"$$source_file\"" >> $@-t; \
	done
	chmod a=r $@-t
	mv $@-t $@

unity.a: unity.o
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ unity.o

# try compiling db_test with unity
unity_test: db/db_test.o db/db_test_util.o $(TESTHARNESS) unity.a
	$(AM_LINK)
	./unity_test

rocksdb.h rocksdb.cc: build_tools/amalgamate.py Makefile $(LIB_SOURCES) unity.cc
	build_tools/amalgamate.py -I. -i./include unity.cc -x include/rocksdb/c.h -H rocksdb.h -o rocksdb.cc

clean:
	rm -f $(BENCHMARKS) $(TOOLS) $(TESTS) $(LIBRARY) $(SHARED)
	rm -rf $(CLEAN_FILES) ios-x86 ios-arm scan_build_report
	find . -name "*.[oda]" -exec rm -f {} \;
	find . -type f -regex ".*\.\(\(gcda\)\|\(gcno\)\)" -exec rm {} \;
	rm -rf bzip2* snappy* zlib* lz4*
	cd java; $(MAKE) clean

tags:
	ctags * -R
	cscope -b `find . -name '*.cc'` `find . -name '*.h'` `find . -name '*.c'`

format:
	build_tools/format-diff.sh

package:
	bash build_tools/make_package.sh $(SHARED_MAJOR).$(SHARED_MINOR)

# ---------------------------------------------------------------------------
# 	Unit tests and tools
# ---------------------------------------------------------------------------
$(LIBRARY): $(LIBOBJECTS)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $(LIBOBJECTS)

$(TOOLS_LIBRARY): $(BENCH_LIB_SOURCES:.cc=.o) $(TOOL_LIB_SOURCES:.cc=.o) $(LIB_SOURCES:.cc=.o) $(TESTUTIL)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $^

librocksdb_env_basic_test.a: util/env_basic_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_AR)rm -f $@
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $^

db_bench: tools/db_bench.o $(BENCHTOOLOBJECTS)
	$(AM_LINK)

cache_bench: util/cache_bench.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

persistent_cache_bench: utilities/persistent_cache/persistent_cache_bench.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

memtablerep_bench: db/memtablerep_bench.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_stress: tools/db_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

write_stress: tools/write_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_sanity_test: tools/db_sanity_test.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

db_repl_stress: tools/db_repl_stress.o $(LIBOBJECTS) $(TESTUTIL)
	$(AM_LINK)

arena_test: util/arena_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

autovector_test: util/autovector_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

column_family_test: db/column_family_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_properties_collector_test: db/table_properties_collector_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

bloom_test: util/bloom_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

dynamic_bloom_test: util/dynamic_bloom_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

c_test: db/c_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

cache_test: util/cache_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

coding_test: util/coding_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

option_change_migration_test: utilities/option_change_migration/option_change_migration_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

stringappend_test: utilities/merge_operators/string_append/stringappend_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

redis_test: utilities/redis/redis_lists_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

hash_table_test: utilities/persistent_cache/hash_table_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

histogram_test: util/histogram_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

thread_local_test: util/thread_local_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

corruption_test: db/corruption_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

crc32c_test: util/crc32c_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

slice_transform_test: util/slice_transform_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_test: db/db_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_test2: db/db_test2.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_block_cache_test: db/db_block_cache_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_bloom_filter_test: db/db_bloom_filter_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_log_iter_test: db/db_log_iter_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_compaction_filter_test: db/db_compaction_filter_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_compaction_test: db/db_compaction_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_dynamic_level_test: db/db_dynamic_level_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_flush_test: db/db_flush_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_inplace_update_test: db/db_inplace_update_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_iterator_test: db/db_iterator_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_memtable_test: db/db_memtable_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_merge_operator_test: db/db_merge_operator_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_options_test: db/db_options_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_range_del_test: db/db_range_del_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_sst_test: db/db_sst_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

external_sst_file_test: db/external_sst_file_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_tailing_iter_test: db/db_tailing_iter_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_iter_test: db/db_iter_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_universal_compaction_test: db/db_universal_compaction_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_wal_test: db/db_wal_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_io_failure_test: db/db_io_failure_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_properties_test: db/db_properties_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_table_properties_test: db/db_table_properties_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

log_write_bench: util/log_write_bench.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK) $(PROFILING_FLAGS)

plain_table_db_test: db/plain_table_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

comparator_db_test: db/comparator_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_reader_bench: table/table_reader_bench.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK) $(PROFILING_FLAGS)

perf_context_test: db/perf_context_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS) $(TerocksLDFLAGS)

prefix_test: db/prefix_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS) $(TerocksLDFLAGS)

backupable_db_test: utilities/backupable/backupable_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

blob_db_test: utilities/blob_db/blob_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

checkpoint_test: utilities/checkpoint/checkpoint_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

document_db_test: utilities/document/document_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

json_document_test: utilities/document/json_document_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

sim_cache_test: utilities/simulator_cache/sim_cache_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

spatial_db_test: utilities/spatialdb/spatial_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_mirror_test: utilities/env_mirror_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

ifdef ROCKSDB_USE_LIBRADOS
env_librados_test: utilities/env_librados_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS) $(COVERAGEFLAGS)
endif

env_registry_test: utilities/env_registry_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

ttl_test: utilities/ttl/ttl_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

date_tiered_test: utilities/date_tiered/date_tiered_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_batch_with_index_test: utilities/write_batch_with_index/write_batch_with_index_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

flush_job_test: db/flush_job_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_iterator_test: db/compaction_iterator_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_job_test: db/compaction_job_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_job_stats_test: db/compaction_job_stats_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compact_on_deletion_collector_test: utilities/table_properties_collectors/compact_on_deletion_collector_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

wal_manager_test: db/wal_manager_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

dbformat_test: db/dbformat_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_basic_test: util/env_basic_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

env_test: util/env_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

fault_injection_test: db/fault_injection_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

rate_limiter_test: util/rate_limiter_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

delete_scheduler_test: util/delete_scheduler_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

filename_test: db/filename_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

file_reader_writer_test: util/file_reader_writer_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

block_based_filter_block_test: table/block_based_filter_block_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

full_filter_block_test: table/full_filter_block_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

log_test: db/log_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

cleanable_test: table/cleanable_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

table_test: table/table_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

block_test: table/block_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

inlineskiplist_test: db/inlineskiplist_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

skiplist_test: db/skiplist_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_edit_test: db/version_edit_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_set_test: db/version_set_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compaction_picker_test: db/compaction_picker_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

version_builder_test: db/version_builder_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

file_indexer_test: db/file_indexer_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

reduce_levels_test: tools/reduce_levels_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_batch_test: db/write_batch_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_controller_test: db/write_controller_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

merge_helper_test: db/merge_helper_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

memory_test: utilities/memory/memory_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

merge_test: db/merge_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

merger_test: table/merger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

util_merge_operators_test: utilities/util_merge_operators_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_file_test: db/options_file_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

deletefile_test: db/deletefile_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

geodb_test: utilities/geodb/geodb_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

rocksdb_dump: tools/dump/rocksdb_dump.o $(LIBOBJECTS)
	$(AM_LINK)

rocksdb_undump: tools/dump/rocksdb_undump.o $(LIBOBJECTS)
	$(AM_LINK)

cuckoo_table_builder_test: table/cuckoo_table_builder_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

cuckoo_table_reader_test: table/cuckoo_table_reader_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

cuckoo_table_db_test: db/cuckoo_table_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

listener_test: db/listener_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

thread_list_test: util/thread_list_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

compact_files_test: db/compact_files_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_test: util/options_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_settable_test: util/options_settable_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

options_util_test: utilities/options/options_util_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

db_bench_tool_test: tools/db_bench_tool_test.o $(BENCHTOOLOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

event_logger_test: util/event_logger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

sst_dump_test: tools/sst_dump_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

column_aware_encoding_test: utilities/column_aware_encoding_test.o $(TESTHARNESS) $(EXPOBJECTS)
	$(AM_LINK)

optimistic_transaction_test: utilities/transactions/optimistic_transaction_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

mock_env_test : util/mock_env_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

manual_compaction_test: db/manual_compaction_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

filelock_test: util/filelock_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

auto_roll_logger_test: db/auto_roll_logger_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

memtable_list_test: db/memtable_list_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

write_callback_test: db/write_callback_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

transaction_test: utilities/transactions/transaction_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

sst_dump: tools/sst_dump.o $(LIBOBJECTS)
	$(AM_LINK)

column_aware_encoding_exp: utilities/column_aware_encoding_exp.o $(EXPOBJECTS)
	$(AM_LINK)

repair_test: db/repair_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

ldb_cmd_test: TerocksLDFLAGS += -lrocksdb -lterark-zip-rocksdb-r
ldb_cmd_test: tools/ldb_cmd_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

ldb: TerocksLDFLAGS += -lrocksdb
ldb: tools/ldb.o
	$(AM_LINK)

iostats_context_test: util/iostats_context_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_V_CCLD)$(CXX) $^ $(EXEC_LDFLAGS) -o $@ $(LDFLAGS) $(TerocksLDFLAGS)

persistent_cache_test: utilities/persistent_cache/persistent_cache_test.o  db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

statistics_test: util/statistics_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

lru_cache_test: util/lru_cache_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

lua_test: utilities/lua/rocks_lua_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

range_del_aggregator_test: db/range_del_aggregator_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

terark_zip_table_db_test: db/terark_zip_table_db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

terark_zip_table_reader_test: table/terark_zip_table_reader_test.o db/db_test_util.o $(LIBOBJECTS) $(TESTHARNESS)
	$(AM_LINK)

#-------------------------------------------------
# make install related stuff
INSTALL_PATH ?= /usr/local

uninstall:
	rm -rf $(INSTALL_PATH)/include/rocksdb \
	  $(INSTALL_PATH)/lib/$(LIBRARY) \
	  $(INSTALL_PATH)/lib/$(SHARED4) \
	  $(INSTALL_PATH)/lib/$(SHARED3) \
	  $(INSTALL_PATH)/lib/$(SHARED2) \
	  $(INSTALL_PATH)/lib/$(SHARED1)

install-headers:
	install -d $(INSTALL_PATH)/lib
	for header_dir in `find "include/rocksdb" -type d`; do \
		install -d $(INSTALL_PATH)/$$header_dir; \
	done
	for header in `find "include/rocksdb" -type f -name *.h`; do \
		install -C -m 644 $$header $(INSTALL_PATH)/$$header; \
	done

install-static: install-headers $(LIBRARY)
	install -C -m 755 $(LIBRARY) $(INSTALL_PATH)/lib

install-shared: install-headers $(SHARED4)
	install -C -m 755 $(SHARED4) $(INSTALL_PATH)/lib && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED3) && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED2) && \
		ln -fs $(SHARED4) $(INSTALL_PATH)/lib/$(SHARED1)

# install static by default + install shared if it exists
install: install-static
	[ -e $(SHARED4) ] && $(MAKE) install-shared || :

#-------------------------------------------------


# ---------------------------------------------------------------------------
# Jni stuff
# ---------------------------------------------------------------------------

JAVA_INCLUDE = -I$(JAVA_HOME)/include/ -I$(JAVA_HOME)/include/linux
ifeq ($(PLATFORM), OS_SOLARIS)
	ARCH := $(shell isainfo -b)
else
	ARCH := $(shell getconf LONG_BIT)
endif
ROCKSDBJNILIB = librocksdbjni-linux$(ARCH).so
ROCKSDB_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-linux$(ARCH).jar
ROCKSDB_JAR_ALL = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH).jar
ROCKSDB_JAVADOCS_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-javadoc.jar
ROCKSDB_SOURCES_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-sources.jar

ifeq ($(PLATFORM), OS_MACOSX)
	ROCKSDBJNILIB = librocksdbjni-osx.jnilib
	ROCKSDB_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-osx.jar
ifneq ("$(wildcard $(JAVA_HOME)/include/darwin)","")
	JAVA_INCLUDE = -I$(JAVA_HOME)/include -I $(JAVA_HOME)/include/darwin
else
	JAVA_INCLUDE = -I/System/Library/Frameworks/JavaVM.framework/Headers/
endif
endif
ifeq ($(PLATFORM), OS_FREEBSD)
	JAVA_INCLUDE += -I$(JAVA_HOME)/include/freebsd
	ROCKSDBJNILIB = librocksdbjni-freebsd$(ARCH).so
	ROCKSDB_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-freebsd$(ARCH).jar
endif
ifeq ($(PLATFORM), OS_SOLARIS)
	ROCKSDBJNILIB = librocksdbjni-solaris$(ARCH).so
	ROCKSDB_JAR = rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-solaris$(ARCH).jar
	JAVA_INCLUDE = -I$(JAVA_HOME)/include/ -I$(JAVA_HOME)/include/solaris
endif

libz.a:
	-rm -rf zlib-1.2.8
	curl -O -L http://zlib.net/zlib-1.2.8.tar.gz
	tar xvzf zlib-1.2.8.tar.gz
	cd zlib-1.2.8 && CFLAGS='-fPIC' ./configure --static && make
	cp zlib-1.2.8/libz.a .

libbz2.a:
	-rm -rf bzip2-1.0.6
	curl -O -L http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
	tar xvzf bzip2-1.0.6.tar.gz
	cd bzip2-1.0.6 && make CFLAGS='-fPIC -O2 -g -D_FILE_OFFSET_BITS=64'
	cp bzip2-1.0.6/libbz2.a .

libsnappy.a:
	-rm -rf snappy-1.1.3
	curl -O -L https://github.com/google/snappy/releases/download/1.1.3/snappy-1.1.3.tar.gz
	tar xvzf snappy-1.1.3.tar.gz
	cd snappy-1.1.3 && ./configure --with-pic --enable-static
	cd snappy-1.1.3 && make
	cp snappy-1.1.3/.libs/libsnappy.a .

liblz4.a:
	   -rm -rf lz4-r127
	   curl -O -L https://codeload.github.com/Cyan4973/lz4/tar.gz/r127
	   mv r127 lz4-r127.tar.gz
	   tar xvzf lz4-r127.tar.gz
	   cd lz4-r127/lib && make CFLAGS='-fPIC' all
	   cp lz4-r127/lib/liblz4.a .

# A version of each $(LIBOBJECTS) compiled with -fPIC and a fixed set of static compression libraries
java_static_libobjects = $(patsubst %,jls/%,$(LIBOBJECTS))
CLEAN_FILES += jls

JAVA_STATIC_FLAGS = -DZLIB -DBZIP2 -DSNAPPY -DLZ4
JAVA_STATIC_INCLUDES = -I./zlib-1.2.8 -I./bzip2-1.0.6 -I./snappy-1.1.3 -I./lz4-r127/lib

$(java_static_libobjects): jls/%.o: %.cc libz.a libbz2.a libsnappy.a liblz4.a
	$(AM_V_CC)mkdir -p $(@D) && $(CXX) $(CXXFLAGS) $(JAVA_STATIC_FLAGS) $(JAVA_STATIC_INCLUDES) -fPIC -c $< -o $@ $(COVERAGEFLAGS)

rocksdbjavastatic: $(java_static_libobjects)
	cd java;$(MAKE) javalib;
	rm -f ./java/target/$(ROCKSDBJNILIB)
	$(CXX) $(CXXFLAGS) -I./java/. $(JAVA_INCLUDE) -shared -fPIC \
	  -o ./java/target/$(ROCKSDBJNILIB) $(JNI_NATIVE_SOURCES) \
	  $(java_static_libobjects) $(COVERAGEFLAGS) \
	  libz.a libbz2.a libsnappy.a liblz4.a $(JAVA_STATIC_LDFLAGS)
	cd java/target;strip -S -x $(ROCKSDBJNILIB)
	cd java;jar -cf target/$(ROCKSDB_JAR) HISTORY*.md
	cd java/target;jar -uf $(ROCKSDB_JAR) $(ROCKSDBJNILIB)
	cd java/target/classes;jar -uf ../$(ROCKSDB_JAR) org/rocksdb/*.class org/rocksdb/util/*.class
	cd java/target/apidocs;jar -cf ../$(ROCKSDB_JAVADOCS_JAR) *
	cd java/src/main/java;jar -cf ../../../target/$(ROCKSDB_SOURCES_JAR) org

rocksdbjavastaticrelease: rocksdbjavastatic
	cd java/crossbuild && vagrant destroy -f && vagrant up linux32 && vagrant halt linux32 && vagrant up linux64 && vagrant halt linux64
	cd java;jar -cf target/$(ROCKSDB_JAR_ALL) HISTORY*.md
	cd java/target;jar -uf $(ROCKSDB_JAR_ALL) librocksdbjni-*.so librocksdbjni-*.jnilib
	cd java/target/classes;jar -uf ../$(ROCKSDB_JAR_ALL) org/rocksdb/*.class org/rocksdb/util/*.class

rocksdbjavastaticpublish: rocksdbjavastaticrelease rocksdbjavastaticpublishcentral

rocksdbjavastaticpublishcentral:
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-javadoc.jar -Dclassifier=javadoc
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-sources.jar -Dclassifier=sources
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-linux64.jar -Dclassifier=linux64
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-linux32.jar -Dclassifier=linux32
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-osx.jar -Dclassifier=osx
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH)-win64.jar -Dclassifier=win64
	mvn gpg:sign-and-deploy-file -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ -DrepositoryId=sonatype-nexus-staging -DpomFile=java/rocksjni.pom -Dfile=java/target/rocksdbjni-$(ROCKSDB_MAJOR).$(ROCKSDB_MINOR).$(ROCKSDB_PATCH).jar

# A version of each $(LIBOBJECTS) compiled with -fPIC
java_libobjects = $(patsubst %,jl/%,$(LIBOBJECTS))
CLEAN_FILES += jl

$(java_libobjects): jl/%.o: %.cc
	$(AM_V_CC)mkdir -p $(@D) && $(CXX) $(CXXFLAGS) -fPIC -c $< -o $@ $(COVERAGEFLAGS)

rocksdbjava: $(java_libobjects)
	$(AM_V_GEN)cd java;$(MAKE) javalib;
	$(AM_V_at)rm -f ./java/target/$(ROCKSDBJNILIB)
	$(AM_V_at)$(CXX) $(CXXFLAGS) -I./java/. $(JAVA_INCLUDE) -shared -fPIC -o ./java/target/$(ROCKSDBJNILIB) $(JNI_NATIVE_SOURCES) $(java_libobjects) $(JAVA_LDFLAGS) $(COVERAGEFLAGS)
	$(AM_V_at)cd java;jar -cf target/$(ROCKSDB_JAR) HISTORY*.md
	$(AM_V_at)cd java/target;jar -uf $(ROCKSDB_JAR) $(ROCKSDBJNILIB)
	$(AM_V_at)cd java/target/classes;jar -uf ../$(ROCKSDB_JAR) org/rocksdb/*.class org/rocksdb/util/*.class

jclean:
	cd java;$(MAKE) clean;

jtest_compile: rocksdbjava
	cd java;$(MAKE) java_test

jtest_run:
	cd java;$(MAKE) run_test

jtest: rocksdbjava
	cd java;$(MAKE) sample;$(MAKE) test;

jdb_bench:
	cd java;$(MAKE) db_bench;

commit_prereq: build_tools/rocksdb-lego-determinator \
               build_tools/precommit_checker.py
	J=$(J) build_tools/precommit_checker.py unit unit_481 clang_unit release release_481 clang_release tsan asan ubsan lite unit_non_shm
	$(MAKE) clean && $(MAKE) jclean && $(MAKE) rocksdbjava;

xfunc:
	for xftest in $(XFUNC_TESTS); do \
		echo "===== Running xftest $$xftest"; \
		make check ROCKSDB_XFUNC_TEST="$$xftest" tests-regexp="DBTest" ;\
	done


# ---------------------------------------------------------------------------
#  	Platform-specific compilation
# ---------------------------------------------------------------------------

ifeq ($(PLATFORM), IOS)
# For iOS, create universal object files to be used on both the simulator and
# a device.
PLATFORMSROOT=/Applications/Xcode.app/Contents/Developer/Platforms
SIMULATORROOT=$(PLATFORMSROOT)/iPhoneSimulator.platform/Developer
DEVICEROOT=$(PLATFORMSROOT)/iPhoneOS.platform/Developer
IOSVERSION=$(shell defaults read $(PLATFORMSROOT)/iPhoneOS.platform/version CFBundleShortVersionString)

.cc.o:
	mkdir -p ios-x86/$(dir $@)
	$(CXX) $(CXXFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -arch x86_64 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	xcrun -sdk iphoneos $(CXX) $(CXXFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -arch armv7s -arch arm64 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

.c.o:
	mkdir -p ios-x86/$(dir $@)
	$(CC) $(CFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -arch x86_64 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	xcrun -sdk iphoneos $(CC) $(CFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -arch armv7s -arch arm64 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

else
.cc.o:
	$(AM_V_CC)$(CXX) $(CXXFLAGS) -c $< -o $@ $(COVERAGEFLAGS)

.c.o:
	$(AM_V_CC)$(CC) $(CFLAGS) -c $< -o $@
endif

# ---------------------------------------------------------------------------
#  	Source files dependencies detection
# ---------------------------------------------------------------------------

all_sources = $(LIB_SOURCES) $(MAIN_SOURCES) $(MOCK_LIB_SOURCES) $(TOOL_LIB_SOURCES) $(BENCH_LIB_SOURCES) $(TEST_LIB_SOURCES) $(EXP_LIB_SOURCES)
DEPFILES = $(all_sources:.cc=.d)

# Add proper dependency support so changing a .h file forces a .cc file to
# rebuild.

# The .d file indicates .cc file's dependencies on .h files. We generate such
# dependency by g++'s -MM option, whose output is a make dependency rule.
$(DEPFILES): %.d: %.cc
	@$(CXX) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) \
	  -MM -MT'$@' -MT'$(<:.cc=.o)' "$<" -o '$@'

depend: $(DEPFILES)

# if the make goal is either "clean" or "format", we shouldn't
# try to import the *.d files.
# TODO(kailiu) The unfamiliarity of Make's conditions leads to the ugly
# working solution.
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),format)
ifneq ($(MAKECMDGOALS),jclean)
ifneq ($(MAKECMDGOALS),jtest)
ifneq ($(MAKECMDGOALS),package)
ifneq ($(MAKECMDGOALS),analyze)
-include $(DEPFILES)
endif
endif
endif
endif
endif
endif
