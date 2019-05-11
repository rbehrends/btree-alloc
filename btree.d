alias Int = ptrdiff_t;

version(UseStructs) {
  struct Node {
    Node *left;
    Node *right;
    this (Node *left, Node *right) {
      this.left = left;
      this.right = right;
    }
    Int checksum() {
      if (left) {
	return 1 + left.checksum() + right.checksum();
      } else {
	return 1;
      }
    }
  }
  alias Tree = Node *;
} else {
  final class Node {
    Node left;
    Node right;
    this() {
    }
    this (Node left, Node right) {
      this.left = left;
      this.right = right;
    }
    Int checksum() {
      if (left) {
	return 1 + left.checksum() + right.checksum();
      } else {
	return 1;
      }
    }
  }
  alias Tree = Node;
}

Tree make_tree(Int depth) {
  if (depth > 0)
    return new Node(make_tree(depth - 1), make_tree(depth - 1));
  else
    return new Node();
}

void delete_tree(out Tree node) {
  node = null;
}


void main(string[] args) {
  import std.stdio, std.conv, core.memory;

  Int n = args.length >= 2 ? to!Int(args[1]) : 21;

  Int min_depth = 4;
  Int max_depth = n;
  if (min_depth + 2 > n)
      max_depth = min_depth + 2;

  Int stretch_depth = max_depth + 1;
  auto stretch_tree = make_tree(stretch_depth);
  writef("stretch tree of depth %d\t check: %d\n", stretch_depth,
      stretch_tree.checksum());

  delete_tree(stretch_tree);
  stretch_tree = null;

  auto long_lived_tree = make_tree(max_depth);

  Int depth;
  for (depth = min_depth; depth <= max_depth; depth += 2) {
    Int iter = 1L << (max_depth - depth + min_depth);
    Int check = 0;
    Int i;
    for (i = 1; i <= iter; i++) {
      auto current_tree = make_tree(depth);
      check += current_tree.checksum();
      delete_tree(current_tree);
    }
    writef("%d\t trees of depth %d\t check: %d\n",
      iter, depth, check);
  }
  writef("long lived tree of depth %d\t check: %d\n",
    max_depth, long_lived_tree.checksum());
  auto gc_stats = GC.stats();
  enum MB = 1024 * 1024;
}
