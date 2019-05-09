type tree = Leaf | Node of tree * tree

let rec make_tree d =
  if d = 0 then Node(Leaf, Leaf)
  else Node(make_tree (d-1), make_tree (d-1))

(* This is not idiomatic OCaml, but we're trying to accurately
 * reflect what the other implementations do. The compiler directive
 * turns off warnings about the pattern match not being exhaustive.
 *)
[@@@ocaml.warning "-P"]
let rec checksum (Node (l, r)) =
  if l == Leaf then 1
  else 1 + checksum l + checksum r

let main () =
  let n = try int_of_string(Array.get Sys.argv 1) with _ -> 21 in
  let min_depth = 4 in
  let max_depth = max n (min_depth + 2) in
  let stretch_depth = max_depth + 1 in
  let stretch_tree = make_tree stretch_depth in
  Printf.printf "stretch tree of depth %d\t check: %d\n"
    stretch_depth (checksum stretch_tree);
  flush stdout;
  let long_lived_tree = make_tree max_depth in
  for d = 0 to (max_depth - min_depth) / 2 do
    let depth = min_depth + d * 2 in
    let iter = 1 lsl (max_depth - depth + min_depth) in
    let check = ref 0 in
    for i = 1 to iter do
      let current_tree = make_tree depth in
      check := !check + checksum current_tree
    done;
    Printf.printf "%d\t trees of depth %d\t check: %d\n"
      iter depth !check;
    flush stdout
  done;
  Printf.printf "long lived tree of depth %i\t check: %i\n"
    max_depth (checksum long_lived_tree)

let () =
  Gc.set { (Gc.get ()) with
    (* Default nursery size is 256k, but we don't run this on
     * 1990's hardware. *)
    Gc.minor_heap_size = 8 * 1024 * 1024;
  };
  main ()
