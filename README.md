# Binary tree benchmarks for various memory allocators

This repository uses the binary trees benchmark of the computer language
benchmark game to compare various memory allocation schemes.

The results should not be generalized for general allocation performance.
Real world programs (especially in languages that support value types) do
not spend nearly as much time allocating and freeing memory, but typically
only 10%-20% of overall CPU time. Performance differences for actual code
will therefore usually be a fraction of the results of this synthetic
benchmark.

The goal of the benchmark is not to make some universal statement about
approaches to allocation, but to dispel generalized preconceptions about
performance of memory management techniques. Other use cases may result in
different performance profiles. For example, data that is not so
pointer-heavy will put less of a burden on GC marking. Performance
can vary greatly by workload.

The code exclusively allocates small objects consisting of two machine
words, which any smart allocator implementation will serve from a pool in
essentially constant time. Calling functions in external libraries and
synchronization can therefore make up a significant part of the allocation
overhead.

The benchmark is specifically designed not to make life easy for garbage
collectors by keeping a large part of the heap alive.

We're measuring throughput only, not pause times, though there is some
instrumentation in the C code to measure pause times if you want to.

A few notes:

* OCaml and Java perform so well because they inline allocations and serve
  them via a bump allocator from the nursery. In addition, OCaml does not
  have to worry about synchronization (currently).
* Garbage collectors can have an advantage over explicit allocators in that
  they can batch deallocations during the sweep phase, whereas explicit
  `free()` has a per-object overhead just to call the function. This
  reduces the amortized cost of freeing memory. This is particularly
  pronounced in this benchmark, where allocators can easily use pool
  allocations to serve the small constant size allocations.
* Garbage collectors can also parallelize much of their work, trading CPU
  load for improved wall clock time. Not all do that, but some do, making
  it important to not just compare wall clock time if total load matters.
* Go is somewhat unfairly disadvantaged; it is designed to turn off its
  write barrier when no collection is happening, but the heavy allocation
  load in this benchmark never allows it to do that.
* Dlmalloc without synchronization benefits greatly from not having to wrap
  allocations with mutex operations. A similar benefit can be achieved by
  having thread-local allocators (e.g. what various GCs do).
* This specific program can obviously be made even faster by using a
  specialized allocator; however, the point is not to optimize the code, but
  to see the cost of regular allocation mechanisms.
* The Boehm GC has a completely undeserved bad reputation. In fact, its
  throughput is generally very good.

Benchmarks were run on Macs, which also accounts for the poor
performance of system malloc() and free() (which have notoriously poorly
performing default implementations in macOS).

Below are the results of sample runs, both on an M1 mini and a 2018
Macbook Pro with a 2.6GHz Core i7 with six cores.

Note that those are a single run each and results can vary somewhat. Again,
the goal is not to say something about typical performance of allocators,
but to show that naive assumptions about the performance of various methods
of memory management may not actually always be true. Therefore, getting
precise measurements was not a priority.

## Results on a Mac M1 mini

```
# jemalloc explicit malloc()/free()
tools/bench.sh ./btree-jemalloc 21
       12.11 real        12.07 user         0.03 sys
# mimalloc explicit malloc()/free()
tools/bench.sh ./btree-mimalloc 21
        4.00 real         3.90 user         0.07 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
tools/bench.sh ./btree-dlmalloc 21
        4.09 real         4.06 user         0.03 sys
# dlmalloc explicit malloc()/free() (threadsafe)
tools/bench.sh ./btree-dlmalloc-lock 21
       12.66 real        12.62 user         0.04 sys
# C++ shared pointers (with mimalloc as base allocator)
tools/bench.sh ./btree-shared-ptr 21
       12.13 real        12.05 user         0.07 sys
# C++ shared pointers + const ref (with mimalloc as base allocator)
tools/bench.sh ./btree-shared-ptr-const-ref 21
        9.48 real         9.39 user         0.07 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 tools/bench.sh ./btree-gc 21
        5.49 real         6.92 user         0.04 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 tools/bench.sh ./btree-gc 21
        6.68 real         6.65 user         0.02 sys
# Boehm GC with four parallel markers and minimal space overhead
GC_MARKERS=4 GC_FREE_SPACE_DIVISOR=10 tools/bench.sh ./btree-gc 21
        5.80 real         8.08 user         0.06 sys
# Boehm GC with single-threaded marking and minimal space overhead
GC_MARKERS=1 GC_FREE_SPACE_DIVISOR=10 tools/bench.sh ./btree-gc 21
        7.80 real         7.77 user         0.02 sys
# Boehm GC with explicit deallocation
tools/bench.sh ./btree-gc-free 21
        8.30 real         8.28 user         0.02 sys
# OCaml
tools/bench.sh ./btree-ml 21
        2.09 real         2.06 user         0.02 sys
# Nim reference counting GC
tools/bench.sh ./btree-nim 21
       12.14 real        12.07 user         0.04 sys
# Nim mark and sweep GC
tools/bench.sh ./btree-nim-ms 21
       11.87 real        11.80 user         0.06 sys
# Nim with ARC and cycle collection enabled
tools/bench.sh ./btree-nim-arc 21
        6.95 real         6.90 user         0.04 sys
# Nim with Boehm GC
GC_MARKERS=1 tools/bench.sh ./btree-nim-boehm 21
        7.35 real         7.31 user         0.03 sys
# D garbage collector (classes)
tools/bench.sh ./btree-d 21
       12.04 real        11.96 user         0.05 sys
# D garbage collector (structs)
tools/bench.sh ./btree-d-struct 21
       17.76 real        17.70 user         0.05 sys
# Go garbage collector
GOMAXPROCS=4 tools/bench.sh ./btree-go 21
       11.40 real        21.35 user         0.11 sys
# Dart garbage collector
tools/bench.sh ./btree-dart 21
        4.71 real         6.40 user         0.40 sys
# Java G1GC garbage collector
tools/bench.sh java -XX:+UseG1GC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        2.01 real         2.25 user         0.15 sys
# Java ZGC garbage collector
tools/bench.sh java -XX:+UseZGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        2.95 real         4.00 user         0.39 sys
# Java Shenandoah garbage collector
tools/bench.sh java -XX:+UseShenandoahGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        2.65 real         3.00 user         0.40 sys
# System malloc()/free()
tools/bench.sh ./btree-sysmalloc 21
       16.57 real        16.07 user         0.49 sys
# Tiny GC (with dlmalloc as base allocator)
tools/bench.sh ./btree-tiny-gc 21
       18.31 real        18.17 user         0.13 sys
```

```
Apple clang version 14.0.0 (clang-1400.0.29.102)
jemalloc 5.3.0
mimalloc 2.0.6
Boehm GC 8.2.2
LDC - the LLVM D compiler (1.30.0):
Nim Compiler Version 1.6.8 [MacOSX: arm64]
go version go1.18.1 darwin/arm64
ocamlopt 4.14.0
Dart SDK version: 2.18.3 (stable) (Mon Oct 17 13:23:20 2022 +0000) on "macos_arm64"
javac 17.0.3
```

## Results on an Intel Macbook Pro

```
# jemalloc explicit malloc()/free()
tools/bench.sh ./btree-jemalloc 21
       12.69 real        12.55 user         0.12 sys
# mimalloc explicit malloc()/free()
tools/bench.sh ./btree-mimalloc 21
        5.85 real         5.63 user         0.12 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
tools/bench.sh ./btree-dlmalloc 21
        6.98 real         6.92 user         0.05 sys
# dlmalloc explicit malloc()/free() (threadsafe)
tools/bench.sh ./btree-dlmalloc-lock 21
       23.71 real        23.64 user         0.06 sys
# C++ shared pointers (with mimalloc as base allocator)
tools/bench.sh ./btree-shared-ptr 21
       25.38 real        25.22 user         0.14 sys
# C++ shared pointers + const ref (with mimalloc as base allocator)
tools/bench.sh ./btree-shared-ptr-const-ref 21
       19.76 real        19.60 user         0.15 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 tools/bench.sh ./btree-gc 21
       10.28 real        12.50 user         0.08 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 tools/bench.sh ./btree-gc 21
       12.04 real        11.97 user         0.05 sys
# Boehm GC with four parallel markers and minimal space overhead
GC_MARKERS=4 GC_FREE_SPACE_DIVISOR=10 tools/bench.sh ./btree-gc 21
       10.75 real        14.05 user         0.08 sys
# Boehm GC with single-threaded marking and minimal space overhead
GC_MARKERS=1 GC_FREE_SPACE_DIVISOR=10 tools/bench.sh ./btree-gc 21
       13.19 real        13.14 user         0.04 sys
# Boehm GC with explicit deallocation
tools/bench.sh ./btree-gc-free 21
       13.78 real        13.73 user         0.03 sys
# OCaml
tools/bench.sh ./btree-ml 21
        3.72 real         3.65 user         0.06 sys
# Nim reference counting GC
tools/bench.sh ./btree-nim 21
       19.32 real        19.22 user         0.08 sys
# Nim mark and sweep GC
tools/bench.sh ./btree-nim-ms 21
       25.02 real        24.84 user         0.15 sys
# Nim with ARC and cycle collection enabled
tools/bench.sh ./btree-nim-arc 21
        9.81 real         9.48 user         0.12 sys
# Nim with Boehm GC
GC_MARKERS=1 tools/bench.sh ./btree-nim-boehm 21
       12.12 real        11.91 user         0.05 sys
# D garbage collector (classes)
tools/bench.sh ./btree-d 21
       26.36 real        26.29 user         0.85 sys
# D garbage collector (structs)
tools/bench.sh ./btree-d-struct 21
       32.06 real        31.99 user         0.85 sys
# Go garbage collector
GOMAXPROCS=4 tools/bench.sh ./btree-go 21
       18.60 real        33.64 user         0.16 sys
# Dart garbage collector
tools/bench.sh ./btree-dart 21
       10.57 real        14.09 user         1.15 sys
# Java G1GC garbage collector
tools/bench.sh java -XX:+UseG1GC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        4.25 real         4.21 user         0.63 sys
# Java ZGC garbage collector
tools/bench.sh java -XX:+UseZGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        6.31 real         7.24 user         1.62 sys
# Java Shenandoah garbage collector
tools/bench.sh java -XX:+UseShenandoahGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21
        5.11 real         5.45 user         1.08 sys
# System malloc()/free()
tools/bench.sh ./btree-sysmalloc 21
       37.08 real        36.31 user         0.58 sys
# Tiny GC (with dlmalloc as base allocator)
tools/bench.sh ./btree-tiny-gc 21
       39.32 real        38.84 user         0.26 sys
```

```
Apple clang version 13.1.6 (clang-1316.0.21.2.5)
jemalloc 5.3.0
mimalloc 2.0.6
Boehm GC 8.2.2
LDC - the LLVM D compiler (1.30.0):
Nim Compiler Version 1.6.8 [MacOSX: amd64]
go version go1.18.1 darwin/amd64
ocamlopt 4.14.0
Dart SDK version: 2.18.3 (stable) (Mon Oct 17 13:23:20 2022 +0000) on "macos_x64"
javac 17.0.3
```
