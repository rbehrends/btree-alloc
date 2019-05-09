import os, strformat, strutils

type
  Node = ref object {.acyclic.}
    left, right: Node

proc bottomUpTree(depth: int): Node =
  if depth > 0:
    Node(left: bottomUpTree(depth-1), right: bottomUpTree(depth-1))
  else:
    Node()

proc itemCheck(node: Node): int =
  if node.left == nil:
    result = 1
  else:
    result = 1 + node.left.itemCheck + node.right.itemCheck

const minDepth = 4

var n =
  if paramCount() > 0:
    paramStr(1).parseInt.int
  else:
    21

let maxDepth = if minDepth + 2 > n: minDepth + 2 else: n
let stretchDepth = maxDepth + 1

var check = bottomUpTree(stretchDepth).itemCheck
echo "stretch tree of depth ", stretchDepth, "\t check: ", check

let longLivedTree = bottomUpTree(maxDepth)

for depth in countup(minDepth, maxDepth, 2):
  let iterations = 1 shl (maxDepth - depth + minDepth)
  check = 0

  for i in 1 .. iterations:
    check += bottomUpTree(depth).itemCheck

  echo((iterations*2), "\t trees of depth ", depth, "\t check: ", check)

echo "long lived tree of depth ", maxDepth, "\t check: ", longLivedTree.itemCheck
