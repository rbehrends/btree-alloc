class btree {

  static class Node {
    Node left, right;
    Node(Node l, Node r) {
      left = l; right = r;
    }
    final int checksum() {
      if (left == null)
        return 1;
      else
        return 1 + left.checksum() + right.checksum();
    }
  }

  static Node make_tree(int depth) {
    if (depth == 0)
      return new Node(null, null);
    else
      return new Node(make_tree(depth-1), make_tree(depth-1));
     
  }

  public static void main(String[] args){
    int min_depth = 4;
    int n = 21;
    if (args.length > 0) n = Integer.parseInt(args[0]);
    int max_depth = (min_depth + 2 > n) ? min_depth + 2 : n;
    int stretch_depth = max_depth + 1;
    Node stretch_tree = make_tree(stretch_depth);
    int check = stretch_tree.checksum();
    stretch_tree = null;
    
    System.out.println(
      "stretch tree of depth "+stretch_depth+"\t check: " + check);
    
    Node long_lived_tree = make_tree(max_depth + 1);
    
    for (int depth=min_depth; depth<=max_depth; depth+=2){
      int iter = 1 << (max_depth - depth + min_depth);
      check = 0;
      
      for (int i=1; i<=iter; i++){
        Node current_tree = make_tree(depth);
        check += current_tree.checksum();
      }
      System.out.println(
        iter + "\t trees of depth " + depth + "\t check: " + check);
    }   
    System.out.println(
      "long lived tree of depth " + max_depth + "\t check: " +
      long_lived_tree.checksum());
  }

}
