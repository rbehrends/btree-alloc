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
       18.10 real        17.99 user         0.09 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 21 >/dev/null
        7.62 real         7.55 user         0.05 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 21 >/dev/null
       27.41 real        27.32 user         0.07 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 21 >/dev/null
        8.55 real        10.93 user         0.09 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 21 >/dev/null
       10.60 real        10.54 user         0.06 sys
# Boehm GC with explicit deallocation
GC_MARKERS=1 /usr/bin/time ./btree-gc-free 21 >/dev/null
       11.98 real        11.93 user         0.04 sys
# Boehm GC with incremental collection (single-threaded)
/usr/bin/time ./btree-gc-inc 21 >/dev/null
       18.53 real        16.86 user         5.07 sys
# OCaml
/usr/bin/time ./btree-ml 21 >/dev/null
        3.70 real         3.62 user         0.07 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 21 >/dev/null
       19.66 real        19.57 user         0.08 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 21 >/dev/null
       23.97 real        23.79 user         0.16 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 21 >/dev/null
        8.74 real        11.22 user         0.09 sys
# D garbage collector
/usr/bin/time ./btree-d 21 >/dev/null
       29.89 real        29.78 user         0.10 sys
# Go garbage collector
/usr/bin/time ./btree-go 21 >/dev/null
       20.94 real        57.99 user         0.18 sys
# Dart garbage collector
/usr/bin/time dart btree.dart 21 >/dev/null
       12.58 real        14.78 user         2.01 sys
# Java default garbage collector
/usr/bin/time java btree 21 >/dev/null
        4.13 real         5.01 user         0.75 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 21 >/dev/null
       64.72 real        64.05 user         0.65 sys
# Tiny GC (w/ dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 21 >/dev/null
       41.27 real        40.92 user         0.31 sys
```

## Results for DEPTH=20

```
$ make benchmark DEPTH=20
# jemalloc explicit malloc()/free()
/usr/bin/time ./btree-jemalloc 20 >/dev/null
        9.00 real         8.95 user         0.04 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 20 >/dev/null
        3.88 real         3.84 user         0.03 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 20 >/dev/null
       13.75 real        13.70 user         0.03 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 20 >/dev/null
        4.07 real         5.02 user         0.05 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 20 >/dev/null
        4.89 real         4.86 user         0.03 sys
# Boehm GC with explicit deallocation
GC_MARKERS=1 /usr/bin/time ./btree-gc-free 20 >/dev/null
        5.73 real         5.70 user         0.02 sys
# Boehm GC with incremental collection (single-threaded)
/usr/bin/time ./btree-gc-inc 20 >/dev/null
        8.57 real         8.08 user         2.58 sys
# OCaml
/usr/bin/time ./btree-ml 20 >/dev/null
        1.79 real         1.73 user         0.05 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 20 >/dev/null
        9.62 real         9.57 user         0.04 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 20 >/dev/null
       12.14 real        12.05 user         0.07 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 20 >/dev/null
        4.22 real         5.22 user         0.05 sys
# D garbage collector
/usr/bin/time ./btree-d 20 >/dev/null
       16.91 real        16.80 user         0.08 sys
# Go garbage collector
/usr/bin/time ./btree-go 20 >/dev/null
       10.64 real        31.47 user         0.17 sys
# Dart garbage collector
/usr/bin/time dart btree.dart 20 >/dev/null
        6.78 real         7.37 user         1.54 sys
# Java default garbage collector
/usr/bin/time java btree 20 >/dev/null
        2.74 real         3.09 user         0.72 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 20 >/dev/null
       32.71 real        32.34 user         0.34 sys
# Tiny GC (w/ dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 20 >/dev/null
       22.05 real        21.71 user         0.30 sys
```

## Software versions

```
$ make version
jemalloc 5.1.0
Apple LLVM version 10.0.1 (clang-1001.0.46.4)
LDC - the LLVM D compiler (1.15.0):
Nim Compiler Version 0.19.9 [MacOSX: amd64]
go version go1.12.4 darwin/amd64
ocamlopt 4.06.0
Dart VM version: 2.3.0 (Fri May 3 10:32:31 2019 +0200) on "macos_x64"
javac 11.0.2
```

The Boehm GC version used is 8.0.4.
