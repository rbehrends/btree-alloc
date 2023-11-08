CC=gcc
CXX=g++
DC=ldc2
GO=go
OCAMLOPT=ocamlopt
DARTCOMP=dart compile exe
OCAMLFLAGS=-O3
NIMC=nim cc
JAVAC=javac
JAVA=java
JAVAFLAGS=-XX:ParallelGCThreads=4 -XX:ConcGCThreads=3
CFLAGS=-O3
CXXFLAGS=-O3 -w
DFLAGS=-O3 -release
NIMFLAGS=-d:release -d:danger --hints=off --warnings=off --verbosity=0 --nimcache=$@.build
LIBGC=-lgc
WITHDLMALLOC=-w -DUSE_DL_PREFIX dlmalloc/dlmalloc.c
WITHTINYGC=-DGC_FASTCALL= -DGC_CLIBDECL= -DGC_STACKBOTTOMVAR=GC_stackend -DGC_CORE_MALLOC=dlmalloc -DGC_CORE_FREE=dlfree tinygc/tinygc.c

BENCH=tools/bench.sh
PROGRAMS=btree-jemalloc \
	 btree-mimalloc \
	 btree-dlmalloc btree-dlmalloc-lock \
	 btree-shared-ptr btree-shared-ptr-const-ref \
	 btree-gc btree-gc-free \
	 btree-ml \
	 btree-nim btree-nim-boehm btree-nim-ms btree-nim-arc \
	 btree-d \
	 btree-d-struct \
	 btree.class \
	 btree-dart \
	 btree-go \
	 btree-sysmalloc \
	 btree-tiny-gc \
	 btree-hs
DEPTH=21

all: $(PROGRAMS)
benchmark: $(PROGRAMS)
	# haskell
	$(BENCH) ./btree-hs $(DEPTH) > /dev/null
	# jemalloc explicit malloc()/free()
	$(BENCH) ./btree-jemalloc $(DEPTH)
	# mimalloc explicit malloc()/free()
	$(BENCH) ./btree-mimalloc $(DEPTH)
	# dlmalloc explicit malloc()/free() (not threadsafe)
	$(BENCH) ./btree-dlmalloc $(DEPTH)
	# dlmalloc explicit malloc()/free() (threadsafe)
	$(BENCH) ./btree-dlmalloc-lock $(DEPTH)
	# C++ shared pointers (with mimalloc as base allocator)
	$(BENCH) ./btree-shared-ptr $(DEPTH)
	# C++ shared pointers + const ref (with mimalloc as base allocator)
	$(BENCH) ./btree-shared-ptr-const-ref $(DEPTH)
	# Boehm GC with four parallel marker threads
	GC_MARKERS=4 $(BENCH) ./btree-gc $(DEPTH)
	# Boehm GC with single-threaded marking
	GC_MARKERS=1 $(BENCH) ./btree-gc $(DEPTH)
	# Boehm GC with four parallel markers and minimal space overhead
	GC_MARKERS=4 GC_FREE_SPACE_DIVISOR=10 $(BENCH) ./btree-gc $(DEPTH)
	# Boehm GC with single-threaded marking and minimal space overhead
	GC_MARKERS=1 GC_FREE_SPACE_DIVISOR=10 $(BENCH) ./btree-gc $(DEPTH)
	# Boehm GC with explicit deallocation
	$(BENCH) ./btree-gc-free $(DEPTH)
	# OCaml
	$(BENCH) ./btree-ml $(DEPTH)
	# Nim reference counting GC
	$(BENCH) ./btree-nim $(DEPTH)
	# Nim mark and sweep GC
	$(BENCH) ./btree-nim-ms $(DEPTH)
	# Nim with ARC and cycle collection enabled
	$(BENCH) ./btree-nim-arc $(DEPTH)
	# Nim with Boehm GC
	GC_MARKERS=1 $(BENCH) ./btree-nim-boehm $(DEPTH)
	# D garbage collector (classes)
	$(BENCH) ./btree-d $(DEPTH)
	# D garbage collector (structs)
	$(BENCH) ./btree-d-struct $(DEPTH)
	# Go garbage collector
	GOMAXPROCS=4 $(BENCH) ./btree-go $(DEPTH)
	# Dart garbage collector
	$(BENCH) ./btree-dart $(DEPTH)
	# Java G1GC garbage collector
	$(BENCH) $(JAVA) -XX:+UseG1GC $(JAVAFLAGS) btree $(DEPTH)
	# Java ZGC garbage collector
	$(BENCH) $(JAVA) -XX:+UseZGC $(JAVAFLAGS) btree $(DEPTH)
	# Java Shenandoah garbage collector
	$(BENCH) $(JAVA) -XX:+UseShenandoahGC $(JAVAFLAGS) btree $(DEPTH)
	# System malloc()/free()
	$(BENCH) ./btree-sysmalloc $(DEPTH)
	# Tiny GC (with dlmalloc as base allocator)
	$(BENCH) ./btree-tiny-gc $(DEPTH)

btree-jemalloc: btree.c
	$(CC) $(CFLAGS) -DUSE_JEMALLOC -o $@ $< -ljemalloc -lm
btree-mimalloc: btree.c
	$(CC) $(CFLAGS) -DUSE_MIMALLOC -o $@ $< -lmimalloc -lm
btree-dlmalloc: btree.c
	$(CC) $(CFLAGS) -DUSE_DLMALLOC $(WITHDLMALLOC) -o $@ $< -lm
btree-dlmalloc-lock: btree.c
	$(CC) $(CFLAGS) -DUSE_DLMALLOC -DUSE_MALLOC_LOCK $(WITHDLMALLOC) -o $@ $< -lm
btree-shared-ptr: btree.cc
	$(CXX) $(CXXFLAGS) -o $@ $< -lmimalloc -lm
btree-shared-ptr-const-ref: btree.cc
	$(CXX) $(CXXFLAGS) -DCONST_REF_ARG=1 -o $@ $< -lmimalloc -lm
btree-gc: btree.c
	$(CC) $(CFLAGS) -DUSE_BOEHM_GC -o $@ $< $(LIBGC) -lm
btree-gc-free: btree.c
	$(CC) $(CFLAGS) -DUSE_BOEHM_GC -DEXPLICIT_FREE -o $@ $< $(LIBGC) -lm
btree-gc-inc: btree.c
	$(CC) $(CFLAGS) -DUSE_BOEHM_GC -DUSE_INC_GC -o $@ $< $(LIBGC) -lm
btree-tiny-gc: btree.c
	$(CC) $(CFLAGS) -DUSE_TINY_GC $(WITHTINYGC) $(WITHDLMALLOC) -o $@ $< -lm
btree-sysmalloc: btree.c
	$(CC) $(CFLAGS) -o $@ $< -lm
btree-nim: btree.nim
	$(NIMC) $(NIMFLAGS) -o=$@ $<
btree-nim-boehm: btree.nim
	$(NIMC) $(NIMFLAGS) --gc=boehm --dynlibOverrideAll --passL:-lgc -d:boehmNoIntPtr -o=$@ $<
btree-nim-ms: btree.nim
	$(NIMC) $(NIMFLAGS) --gc=markandsweep -o=$@ $<
btree-nim-arc: btree.nim
	$(NIMC) $(NIMFLAGS) --gc=orc -o=$@ $<
btree-d: btree.d
	$(DC) $(DFLAGS) -of=$@ $<
btree-d-struct: btree.d
	$(DC) $(DFLAGS) -d-version=UseStructs -of=$@ $<
btree-go: btree.go
	$(GO) build -o $@ $<
btree-hs: btree-hs.lhs
	stack ghc -- --make -O3 $<
btree-ml: btree.ml
	$(OCAMLOPT) $(OCAMLFLAGS) -o $@ $<
btree.class: btree.java
	$(JAVAC) $<
btree-dart: btree.dart
	$(DARTCOMP) -o $@ $<
btree-swift: btree.swift
	$(SWIFTC) $(SWIFTFLAGS) -o $@ $<

version:
	@$(CC) -v 2>&1 | egrep ' version '
	@printf "jemalloc "; jemalloc-config --version | sed -e 's/-.*//'
	@printf '#include <mimalloc.h>\nMI_MALLOC_VERSION'| gcc -E - | tail -1 | awk '{print "mimalloc " int($$1/100) "." int($$1 % 100 / 10) "." int($$1 % 10) }'
	@printf '#include <gc/gc.h>\nGC_VERSION_MAJOR GC_VERSION_MINOR GC_VERSION_MICRO'| gcc -E - | tail -1 | awk '{print "Boehm GC "$$1"."$$2"."$$3 }'
	@$(DC) --version | head -1
	@$(NIMC)  --version | head -1
	@go version
	@printf "ocamlopt "; ocamlopt -version
	@dart --version
	@javac -version

clean:
	rm -f $(PROGRAMS)
	rm -rf btree*.o btree.cm? btree*.class btree*.dill btree*.build
.PHONY: all benchmark clean version
.FORCE:
