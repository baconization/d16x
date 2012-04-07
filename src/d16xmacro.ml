(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;



let rec compile_macros full_tree =
   let inline_indexer = (function (tree, map) ->
                     match tree with
                        TreeExpression("INLINE", [TreeIdent(ident);body]) -> (true, StringMap.add ident body map)
                     | _ -> (false, map)) in
   let macro_map = tree_hunt inline_indexer full_tree in
   let clean_tree = rewrite full_tree (function (name, _) -> name = "INLINE") (function _ -> TreeNoOp) in
      rewrite clean_tree (function (name, _) -> StringMap.mem name macro_map) (function (name, children) -> StringMap.find name macro_map);;



