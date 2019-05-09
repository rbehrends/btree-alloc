package main

import (
	"os"
	"fmt"
	"strconv"
)

type Node struct {
	left, right *Node
}

func make_tree(depth int) *Node {
	if depth == 0 {
		return &Node{}
	} else {
		return &Node{make_tree(depth - 1), make_tree(depth - 1)}
	}
}

func (node *Node) checksum() int {
	if node.left == nil {
		return 1
	} else {
		return 1 + node.left.checksum() + node.right.checksum()
	}
}

func main() {
	var n = 21
	const min_depth = 4
	if len(os.Args) > 1 {
		n, _ = strconv.Atoi(os.Args[1])
	}

	var max_depth = n
	if min_depth+2 > n {
		max_depth = min_depth + 2
	}
	var stretch_depth = max_depth + 1
	var stretch_tree = make_tree(stretch_depth);
	var check = stretch_tree.checksum();
	stretch_tree = nil;
	fmt.Printf("stretch tree of depth %d\t check: %d\n",
		stretch_depth, check)

	var long_lived_tree = make_tree(max_depth)

	for depth := min_depth; depth <= max_depth; depth += 2 {
		var iter = 1 << uint(max_depth-depth+min_depth)
		check = 0

		for i := 1; i <= iter; i++ {
			check += make_tree(depth).checksum()
		}
		fmt.Printf("%d\t trees of depth %d\t check: %d\n",
			iter, depth, check)
	}
	fmt.Printf("long lived tree of depth %d\t check: %d\n",
		max_depth, long_lived_tree.checksum())
}
