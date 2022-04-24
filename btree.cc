#include <cstdint>
#include <cstdio>
#include <memory>
#include <mimalloc.h>

using std::shared_ptr;

typedef intptr_t Int;

void *operator new(size_t size) {
  return mi_malloc(size);
}

void operator delete(void *p) {
  mi_free(p);
}

typedef struct Node {
  shared_ptr<Node> left;
  shared_ptr<Node> right;
} Node;

typedef shared_ptr<Node> NodePtr;

#ifdef CONST_REF_ARG
#define NodePtrArg const NodePtr &
#else
#define NodePtrArg NodePtr
#endif

NodePtr make_node(NodePtrArg left, NodePtrArg right) {
  NodePtr result = std::make_shared<Node>();
  result->left = left;
  result->right = right;
  return result;
}

Int checksum(NodePtrArg node) {
  if (node->left)
    return 1 + checksum(node->left) + checksum(node->right);
  else
    return 1;
}

NodePtr make_tree(Int depth) {
  if (depth > 0)
    return make_node(make_tree(depth - 1), make_tree(depth - 1));
  else
    return make_node(nullptr, nullptr);
}

void delete_tree(NodePtr &node) {
  node = nullptr;
}

void trees(Int n) {
  Int min_depth = 4;
  Int max_depth = n;
  if (min_depth + 2 > n)
      max_depth = min_depth + 2;

  Int stretch_depth = max_depth + 1;
  NodePtr stretch_tree = make_tree(stretch_depth);
  printf("stretch tree of depth %ld\t check: %ld\n", stretch_depth,
      checksum(stretch_tree));

  delete_tree(stretch_tree);
  stretch_tree = nullptr;

  NodePtr long_lived_tree = make_tree(max_depth);

  Int depth;
  for (depth = min_depth; depth <= max_depth; depth += 2) {
    Int iter = 1L << (max_depth - depth + min_depth);
    Int check = 0;
    Int i;
    for (i = 1; i <= iter; i++) {
      NodePtr current_tree = make_tree(depth);
      check += checksum(current_tree);
      delete_tree(current_tree);
    }
    printf("%ld\t trees of depth %ld\t check: %ld\n",
      iter, depth, check);
  }
  printf("long lived tree of depth %ld\t check: %ld\n",
    max_depth, checksum(long_lived_tree));

}

int main(int argc, char *argv[]) {
  Int n = argc >= 2 ? atol(argv[1]) : 21;
  trees(n);
  return 0;
}
