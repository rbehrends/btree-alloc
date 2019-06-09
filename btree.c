#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#ifdef USE_BOEHM_GC
#include <gc/gc.h>
#include <sys/time.h>
#ifdef USE_INC_GC
void no_warn(char *msg, GC_word arg) { }
#define INIT GC_set_warn_proc(no_warn); GC_set_handle_fork(0); \
  GC_enable_incremental(); GC_INIT(); GC_set_full_freq(1000000000);
#else
#define INIT GC_INIT();
#endif
#define MALLOC(n) (GC_malloc(n))
#ifdef EXPLICIT_FREE
#define FREE(p) (GC_free(p))
#else
#define FREE(p) ((void) 0)
#endif
#elif defined(USE_JEMALLOC)
#include <jemalloc/jemalloc.h>
#define INIT ((void) 0)
#define MALLOC(n) (malloc(n))
#define FREE(p) (free(p))
#elif defined(USE_DLMALLOC)
extern void *dlmalloc(size_t);
extern void dlfree(void *);
#define INIT ((void) 0)
#define MALLOC(n) (dlmalloc(n))
#define FREE(p) (dlfree(p))
#elif defined(USE_TINY_GC)
#include "gc/gc.h"
#define INIT GC_INIT()
#define MALLOC(n) (GC_malloc(n))
#ifdef EXPLICIT_FREE
#define FREE(p) (GC_free(p))
#else
#define FREE(p) ((void) 0)
#endif
#else
#include <stdlib.h>
#define INIT ((void) 0)
#define MALLOC(n) (malloc(n))
#define FREE(p) (free(p))
#endif

typedef intptr_t Int;

typedef struct Node {
  struct Node *left;
  struct Node *right;
} Node;

Node *make_node(Node *left, Node *right) {
  Node *result = (Node *)MALLOC(sizeof(Node));
  result->left = left;
  result->right = right;
  return result;
}

Int checksum(Node *node) {
  if (node->left)
    return 1 + checksum(node->left) + checksum(node->right);
  else
    return 1;
}

Node* make_tree(Int depth) {
  if (depth > 0)
    return make_node(make_tree(depth - 1), make_tree(depth - 1));
  else
    return make_node(NULL, NULL);
}

void delete_nodes(Node* node) {
  if (node->left)
  {
    delete_nodes(node->left);
    delete_nodes(node->right);
  }
  FREE(node);
}

#if !(defined(USE_BOEHM_GC) || defined(USE_TINY_GC)) || defined(EXPLICIT_FREE)
void delete_tree(Node *node) {
  if (node)
    delete_nodes(node);
}
#else
#define delete_tree(node) node = NULL
#endif

#ifdef USE_BOEHM_GC
int collections = 0;
double collection_time = 0.0;
double max_collection_time = 0.0;

#ifdef USE_INC_GC
#define START_EVENT GC_EVENT_MARK_START
#define STOP_EVENT GC_EVENT_RECLAIM_END
#else
#define START_EVENT GC_EVENT_START
#define STOP_EVENT GC_EVENT_END
#endif

void GCTrackStats(GC_EventType ev) {
  static struct timeval tstart, tend;
  switch (ev) {
    case START_EVENT:
      gettimeofday(&tstart, NULL);
      break;
    case STOP_EVENT:
      gettimeofday(&tend, NULL);
      collections++;
      double t =
        (tend.tv_sec + tend.tv_usec / 1000000.0) -
        (tstart.tv_sec + tstart.tv_usec / 1000000.0);
      collection_time += t;
      if (t > max_collection_time)
        max_collection_time = t;
      break;
    default:
      break;
  }
}
#endif


void trees(Int n) {
  Int min_depth = 4;
  Int max_depth = n;
  if (min_depth + 2 > n)
      max_depth = min_depth + 2;

  Int stretch_depth = max_depth + 1;
  Node *stretch_tree = make_tree(stretch_depth);
  printf("stretch tree of depth %ld\t check: %ld\n", stretch_depth,
      checksum(stretch_tree));

  delete_tree(stretch_tree);
  stretch_tree = NULL;

  Node *long_lived_tree = make_tree(max_depth);

  Int depth;
  for (depth = min_depth; depth <= max_depth; depth += 2) {
    Int iter = 1L << (max_depth - depth + min_depth);
    Int check = 0;
    Int i;
    for (i = 1; i <= iter; i++) {
      Node *current_tree = make_tree(depth);
      check += checksum(current_tree);
      delete_tree(current_tree);
    }
    printf("%ld\t trees of depth %ld\t check: %ld\n",
      iter, depth, check);
  }
  printf("long lived tree of depth %ld\t check: %ld\n",
    max_depth, checksum(long_lived_tree));

#ifdef USE_BOEHM_GC
  struct GC_prof_stats_s prof;
  const Int MB = 1024 * 1024;
  GC_get_prof_stats(&prof, sizeof(prof));
  printf("%8d collections\n"
         "%8.3lf seconds/collection\n"
         "%8.3lf max seconds/collection\n"
         "%8ld MB heap size\n"
         "%8ld MB free bytes\n",
    collections, collection_time/(double)collections,
    max_collection_time, prof.heapsize_full/MB, prof.free_bytes_full/MB);
#endif
}

void *GC_stackend;

int main(int argc, char *argv[]) {
#if defined(USE_BOEHM_GC) || defined(USE_TINY_GC)
  GC_set_all_interior_pointers(0);
#endif
  INIT;
#ifdef USE_TINY_GC
  static void *dummy[1];
  GC_add_roots(dummy, dummy+1);
  GC_stackend = &argc;
#endif
#ifdef USE_BOEHM_GC
#ifdef EXPLICIT_FREE
  GC_disable();
#endif
  GC_set_on_collection_event(GCTrackStats);
#endif

  Int n = argc >= 2 ? atol(argv[1]) : 21;
  trees(n);
  return 0;
}
