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

* OCaml and Java perform so well, because they inline allocations and serve
  them via a bump allocator from the nursery. In addition, OCaml does not
  have to worry about synchronization.
* Garbage collectors have an advantage over explicit allocators in that
  they can batch deallocations during the sweep phase, whereas explicit
  `free()` has a per-object overhead just to call the function. This
  reduces the amortized cost of freeing memory.
* Garbage collectors can also parallelize most of their work, trading CPU
  load for improved wall clock time. Not all do that, but some do, making
  it important to not just compare wall clock time if total load matters.
* Go is somewhat unfairly disadvantaged; it is designed to turn off its
  write barrier when no collection is happening, but the unusual allocation
  load in this benchmark never allows it to do that.
* Dlmalloc without synchronization benefits greatly from not having to wrap
  allocations with mutex operations. A similar benefit can be achieved by
  having thread-local allocators (e.g. what various GCs do).
* This specific program can obviously be made even faster by using a
  specialized allocator; however, the point is not to optimize the code, but
  to see the cost of regular allocation mechanisms.
* The Boehm GC has a completely undeserved bad reputation. In fact, its
  performance is generally very good.

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
/usr/bin/time ./btree-jemalloc 21 >/dev/null
       11.02 real        10.98 user         0.02 sys
# mimalloc explicit malloc()/free()
/usr/bin/time ./btree-mimalloc 21 >/dev/null
        3.96 real         3.94 user         0.01 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 21 >/dev/null
        4.28 real         4.25 user         0.02 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 21 >/dev/null
       12.65 real        12.60 user         0.03 sys
# C++ shared pointers (with mimalloc as base allocator)
/usr/bin/time ./btree-shared-ptr 21 >/dev/null
       12.13 real        12.04 user         0.07 sys
# C++ shared pointers + const ref (with mimalloc as base allocator)
/usr/bin/time ./btree-shared-ptr-const-ref 21 >/dev/null
        9.46 real         9.37 user         0.07 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 21 >/dev/null
        6.13 real         8.35 user         0.05 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 21 >/dev/null
        8.12 real         8.10 user         0.02 sys
# Boehm GC with four parallel markers and minimal space overhead
GC_MARKERS=4 GC_FREE_SPACE_DIVISOR=10 /usr/bin/time ./btree-gc 21 >/dev/null
        6.14 real         8.39 user         0.05 sys
# Boehm GC with single-threaded marking and minimal space overhead
GC_MARKERS=1 GC_FREE_SPACE_DIVISOR=10 /usr/bin/time ./btree-gc 21 >/dev/null
        8.16 real         8.14 user         0.02 sys
# Boehm GC with explicit deallocation
/usr/bin/time ./btree-gc-free 21 >/dev/null
        8.66 real         8.63 user         0.02 sys
# OCaml
/usr/bin/time ./btree-ml 21 >/dev/null
        2.10 real         2.07 user         0.02 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 21 >/dev/null
       13.23 real        13.19 user         0.03 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 21 >/dev/null
       12.78 real        12.71 user         0.05 sys
# Nim with ARC and cycle collection enabled
/usr/bin/time ./btree-nim-arc 21 >/dev/null
        6.98 real         6.93 user         0.04 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 21 >/dev/null
        6.74 real         9.04 user         0.05 sys
# D garbage collector (classes)
/usr/bin/time ./btree-d 21 >/dev/null
       12.73 real        12.67 user         0.04 sys
# D garbage collector (structs)
/usr/bin/time ./btree-d-struct 21 >/dev/null
       18.64 real        18.59 user         0.03 sys
# Go garbage collector
GOMAXPROCS=4 /usr/bin/time ./btree-go 21 >/dev/null
       11.21 real        21.24 user         0.09 sys
# Dart garbage collector
/usr/bin/time ./btree-dart 21 >/dev/null
        6.10 real         7.88 user         0.52 sys
# Java G1GC garbage collector
/usr/bin/time java -XX:+UseG1GC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        3.75 real         3.49 user         0.67 sys
# Java ZGC garbage collector
/usr/bin/time java -XX:+UseZGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        4.83 real         6.47 user         1.33 sys
# Java Shenandoah garbage collector
/usr/bin/time java -XX:+UseShenandoahGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        3.80 real         5.41 user         0.78 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 21 >/dev/null
       38.02 real        37.72 user         0.28 sys
# Tiny GC (with dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 21 >/dev/null
       18.42 real        18.30 user         0.10 sys
```

```
Apple clang version 13.0.0 (clang-1300.0.29.30)
jemalloc 5.2.1
mimalloc 1.7.1
Boehm GC 8.0.6
LDC - the LLVM D compiler (1.29.0):
Nim Compiler Version 1.6.4 [MacOSX: arm64]
go version go1.18.1 darwin/arm64
ocamlopt 4.12.1
Dart SDK version: 2.16.2 (stable) (Tue Mar 22 13:15:13 2022 +0100) on "macos_arm64"
javac 17.0.3
```

## Results on a Macbook Pro

```
# jemalloc explicit malloc()/free()
/usr/bin/time ./btree-jemalloc 21 >/dev/null
       15.96 real        15.62 user         0.10 sys
# mimalloc explicit malloc()/free()
/usr/bin/time ./btree-mimalloc 21 >/dev/null
        6.59 real         6.26 user         0.03 sys
# dlmalloc explicit malloc()/free() (not threadsafe)
/usr/bin/time ./btree-dlmalloc 21 >/dev/null
        7.97 real         7.76 user         0.07 sys
# dlmalloc explicit malloc()/free() (threadsafe)
/usr/bin/time ./btree-dlmalloc-lock 21 >/dev/null
       25.89 real        25.66 user         0.07 sys
# C++ shared pointers (with mimalloc as base allocator)
/usr/bin/time ./btree-shared-ptr 21 >/dev/null
       26.53 real        26.16 user         0.21 sys
# C++ shared pointers + const ref (with mimalloc as base allocator)
/usr/bin/time ./btree-shared-ptr-const-ref 21 >/dev/null
       20.12 real        19.75 user         0.21 sys
# Boehm GC with four parallel marker threads
GC_MARKERS=4 /usr/bin/time ./btree-gc 21 >/dev/null
       10.95 real        14.51 user         0.10 sys
# Boehm GC with single-threaded marking
GC_MARKERS=1 /usr/bin/time ./btree-gc 21 >/dev/null
       13.39 real        13.33 user         0.05 sys
# Boehm GC with four parallel markers and minimal space overhead
GC_MARKERS=4 GC_FREE_SPACE_DIVISOR=10 /usr/bin/time ./btree-gc 21 >/dev/null
       10.41 real        14.23 user         0.09 sys
# Boehm GC with single-threaded marking and minimal space overhead
GC_MARKERS=1 GC_FREE_SPACE_DIVISOR=10 /usr/bin/time ./btree-gc 21 >/dev/null
       13.59 real        13.52 user         0.05 sys
# Boehm GC with explicit deallocation
/usr/bin/time ./btree-gc-free 21 >/dev/null
       13.43 real        13.22 user         0.04 sys
# OCaml
/usr/bin/time ./btree-ml 21 >/dev/null
        4.17 real         3.94 user         0.07 sys
# Nim reference counting GC
/usr/bin/time ./btree-nim 21 >/dev/null
       19.66 real        19.41 user         0.09 sys
# Nim mark and sweep GC
/usr/bin/time ./btree-nim-ms 21 >/dev/null
       26.33 real        25.99 user         0.16 sys
# Nim with ARC and cycle collection enabled
/usr/bin/time ./btree-nim-arc 21 >/dev/null
        9.98 real         9.71 user         0.13 sys
# Nim with Boehm GC
GC_MARKERS=4 /usr/bin/time ./btree-nim-boehm 21 >/dev/null
       10.66 real        14.26 user         0.09 sys
# D garbage collector (classes)
/usr/bin/time ./btree-d 21 >/dev/null
       26.25 real        26.25 user         0.84 sys
# D garbage collector (structs)
/usr/bin/time ./btree-d-struct 21 >/dev/null
       32.35 real        32.32 user         0.85 sys
# Go garbage collector
GOMAXPROCS=4 /usr/bin/time ./btree-go 21 >/dev/null
       19.06 real        34.24 user         0.20 sys
# Dart garbage collector
/usr/bin/time ./btree-dart 21 >/dev/null
       12.59 real        15.50 user         1.18 sys
# Java G1GC garbage collector
/usr/bin/time java -XX:+UseG1GC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        4.64 real         4.64 user         0.78 sys
# Java ZGC garbage collector
/usr/bin/time java -XX:+UseZGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        7.22 real        10.54 user         2.02 sys
# Java Shenandoah garbage collector
/usr/bin/time java -XX:+UseShenandoahGC -XX:ParallelGCThreads=4 -XX:ConcGCThreads=3 btree 21 >/dev/null
        5.33 real         7.61 user         1.18 sys
# System malloc()/free()
/usr/bin/time ./btree-sysmalloc 21 >/dev/null
       37.10 real        36.20 user         0.60 sys
# Tiny GC (with dlmalloc as base allocator)
/usr/bin/time ./btree-tiny-gc 21 >/dev/null
       40.71 real        40.24 user         0.26 sys
```

```
Apple clang version 13.1.6 (clang-1316.0.21.2.3)
jemalloc 5.2.1
mimalloc 1.7.1
Boehm GC 8.0.6
LDC - the LLVM D compiler (1.29.0):
Nim Compiler Version 1.6.4 [MacOSX: amd64]
go version go1.18.1 darwin/amd64
ocamlopt 4.12.0
Dart SDK version: 2.16.2 (stable) (Tue Mar 22 13:15:13 2022 +0100) on "macos_x64"
javac 17.0.3
```
