# Binary tree benchmarks for various memory allocators

This repository uses the binary trees benchmark of the computer language
benchmark game to compare various memory allocation schemes.

The results should not be generalized for general allocation performance.
Real world programs (especially in languages that support value types) do
not spend nearly as much time allocating and freeing memory, typically
10%-20% of overall CPU time. Performance differences for actual code will
therefore usually be a fraction of the results of this synthetic benchmark.

The goal of the benchmark is not to make some universal statement about
approaches to allocation, but to dispel generalized preconceptions about
performance of memory management techniques. Other use cases may result in
different performance profiles. For example, data that is not so
pointer-heavy will put less of a burden on GC marking.

The code exclusively allocates small objects consisting of two machine
words, which any smart allocator implementation will serve from a pool in
essentially constant time. Calling functions in external libraries and
synchronization can therefore make up a significant part of the allocation
overhead.

The benchmark is specifically designed not to make life easy for garbage
collectors by keeping a large part of the heap alive.

We're measuring throughput only, not pause times, though there is some
instrumentation in the C code to measure pause times.

A few notes:

* OCaml and Java perform so well, because they inline allocations and serve
  them via a bump allocator from the nursery. In addition, OCaml does not
  have to worry about synchronization.
* Garbage collectors have an advantage over explicit allocators in that
  they can batch deallocations during the sweep phase, whereas explicit
  `free()` has a per-object overhead just to call the function. This
  reduces the amortized overhead for freeing memory.
* Garbage collectors can also parallelize most of their work, trading CPU
  load for improved wall clock time. Not all do that, but some do, making
  it important to not just compare wall clock time if total load matters.
* Go is somewhat unfairly disadvantaged; it is designed to turn off its
  write barrier when no collection is happening, but the unusual allocation
  load never allows it to do that.
* Dlmalloc without synchronization benefits greatly from not having to wrap
  allocations with mutex operations. A similar benefit can be achieved by
  having thread-local allocators (e.g. what various GCs do).
* This specific program can obviously be made even faster by using a
  specialized allocator; however, the point is not to optimize the code, but
  to see the cost of regular allocation mechanisms.
* Somewhat surprisingly, the largest pause times are (without revisions to
  the code) incurred by explicit deallocation strategies, not by mark and
  sweep collectors. This is because deallocating a large tree is more
  expensive than a full GC sweep phase due to a larger per-object overhead.
  The code can be rewritten to break up such large deallocations, but may
  not look as natural anymore.

Benchmarks were run on a Mac, which accounts in large part for the poor
performance of system malloc() and free(). The processor was a 2.6 GHz Intel
Core i7 with six cores.

Below are the results of sample runs, for `make benchmark DEPTH=21` and
`make benchmark DEPTH=20`. See the `Makefile` for further configuration
options, such as the choice of compilers and compiler flags.

Note that those are a single run each and results can vary somewhat. Again,
the goal is not to say something about typical performance of allocators,
but to show that naive assumptions about the performance of various methods
of memory management may not actually always be true. Therefore, getting
precise measurements was not a priority.

## Results for DEPTH=21

```
$ make benchmark DEPTH=21
# jemalloc explicit malloc()/free()
/usr/bin/time ./btree-jemalloc 21 >/dev/null
       17.68 real        17.54 user         0.13 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 21 >/dev/null
        7.41 real         7.35 user         0.05 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 21 >/dev/null
       26.60 real        26.53 user         0.06 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 21 >/dev/null
        8.91 real        11.40 user         0.08 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 21 >/dev/null
       11.07 real        11.02 user         0.05 sys
# Boehm GC with explicit deallocation
GC_MARKERS=1 /usr/bin/time ./btree-gc-free 21 >/dev/null
       12.49 real        12.44 user         0.03 sys
# Boehm GC with incremental collection
GC_MARKERS=4 /usr/bin/time ./btree-gc-inc 21 >/dev/null
       18.16 real        15.02 user         4.19 sys
# OCaml
/usr/bin/time ./btree-ml 21 >/dev/null
        3.57 real         3.50 user         0.06 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 21 >/dev/null
       19.16 real        19.08 user         0.07 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 21 >/dev/null
       23.51 real        23.36 user         0.13 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 21 >/dev/null
        9.38 real        12.04 user         0.08 sys
# D garbage collector (classes)
/usr/bin/time ./btree-d 21 >/dev/null
       29.17 real        29.08 user         0.08 sys
# D garbage collector (structs)
/usr/bin/time ./btree-d-struct 21 >/dev/null
       34.35 real        34.29 user         0.05 sys
# Go garbage collector
GOMAXPROCS=4 /usr/bin/time ./btree-go 21 >/dev/null
       21.99 real        34.21 user         0.11 sys
# Dart garbage collector
/usr/bin/time dartaotruntime --marker-tasks=1 btree-dart.aot 21 >/dev/null
       10.46 real        12.10 user         0.86 sys
# Java default garbage collector
/usr/bin/time java -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        4.21 real         4.44 user         0.67 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 21 >/dev/null
       64.20 real        63.50 user         0.68 sys
# Tiny GC (w/ dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 21 >/dev/null
       39.89 real        39.61 user         0.26 sys
```

## Results for DEPTH=20

```
$ make benchmark DEPTH=20
# jemalloc explicit malloc()/free()
/usr/bin/time ./btree-jemalloc 20 >/dev/null
        8.70 real         8.64 user         0.05 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 20 >/dev/null
        3.82 real         3.78 user         0.03 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 20 >/dev/null
       13.60 real        13.56 user         0.03 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 20 >/dev/null
        4.33 real         5.35 user         0.05 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 20 >/dev/null
        5.14 real         5.11 user         0.02 sys
# Boehm GC with explicit deallocation
GC_MARKERS=1 /usr/bin/time ./btree-gc-free 20 >/dev/null
        6.25 real         6.23 user         0.01 sys
# Boehm GC with incremental collection
GC_MARKERS=4 /usr/bin/time ./btree-gc-inc 20 >/dev/null
        8.68 real         7.43 user         2.05 sys
# OCaml
/usr/bin/time ./btree-ml 20 >/dev/null
        1.79 real         1.73 user         0.05 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 20 >/dev/null
        9.31 real         9.26 user         0.04 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 20 >/dev/null
       11.88 real        11.81 user         0.07 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 20 >/dev/null
        4.57 real         5.64 user         0.05 sys
# D garbage collector (classes)
/usr/bin/time ./btree-d 20 >/dev/null
       16.08 real        16.01 user         0.06 sys
# D garbage collector (structs)
/usr/bin/time ./btree-d-struct 20 >/dev/null
       17.10 real        17.06 user         0.03 sys
# Go garbage collector
GOMAXPROCS=4 /usr/bin/time ./btree-go 20 >/dev/null
       10.24 real        17.41 user         0.06 sys
# Dart garbage collector
/usr/bin/time dartaotruntime --marker-tasks=1 btree-dart.aot 20 >/dev/null
        4.67 real         5.31 user         0.45 sys
# Java default garbage collector
/usr/bin/time java -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 20 >/dev/null
        2.42 real         2.44 user         0.48 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 20 >/dev/null
       31.88 real        31.53 user         0.35 sys
# Tiny GC (w/ dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 20 >/dev/null
       21.32 real        21.06 user         0.25 sys
```

## Software versions

```
$ make version
jemalloc 5.1.0
Boehm GC 8.0.4
Apple LLVM version 10.0.1 (clang-1001.0.46.4)
LDC - the LLVM D compiler (1.15.0):
Nim Compiler Version 0.20.99 [MacOSX: amd64]
go version go1.12.5 darwin/amd64
ocamlopt 4.06.0
Dart VM version: 2.3.1 (Tue May 21 19:28:38 2019 +0200) on "macos_x64"
javac 11.0.2
```
