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
   let do_subs (name, children) =
      (let childmap = list_to_childmap children in
         rewrite (StringMap.find name macro_map) (function (id, _) -> (StringMap.mem id childmap)) (function (id, _) -> (StringMap.find id childmap))
      ) in
      rewrite clean_tree (function (name, _) -> StringMap.mem name macro_map) do_subs;;



