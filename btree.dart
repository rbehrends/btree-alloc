class Node {
  final Node? left, right;
  Node(this.left, this.right);
  int checksum() {
    if (left == null)
      return 1;
    else
      return 1 + left!.checksum() + right!.checksum();
  }
}

Node make_tree(int depth) {
  if (depth == 0)
    return Node(null, null);
  else
    return Node(make_tree(depth - 1), make_tree(depth - 1));
}

void main(List<String> args) {
  int min_depth = 4;
  int n = 21;
  if (args.length > 0) n = int.parse(args[0]);
  int max_depth = (min_depth + 2 > n) ? min_depth + 2 : n;
  int stretch_depth = max_depth + 1;
  Node? stretch_tree = make_tree(stretch_depth);
  int check = stretch_tree.checksum();

  print("stretch tree of depth ${stretch_depth}\t check: ${check}");
  stretch_tree = null;

  var long_lived_tree = make_tree(max_depth + 1);

  for (int depth = min_depth; depth <= max_depth; depth += 2) {
    int iter = 1 << (max_depth - depth + min_depth);
    check = 0;

    for (int i = 1; i <= iter; i++) {
      var current_tree = make_tree(depth);
      check += current_tree.checksum();
    }
    print("${iter}\t trees of depth ${depth}\t check: ${check}");
  }
  print("long lived tree of depth ${max_depth}\t " +
      "check: ${long_lived_tree.checksum()}");
}
