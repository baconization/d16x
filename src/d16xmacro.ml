(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

exception CantFix;;

let ctx_counter = ref 0;;

let get_ctx () =
   ctx_counter := !ctx_counter + 1; string_of_int(!ctx_counter);;

let rec compile_macros full_tree =
   let fix_labels new_tree ctx =
      (let lbl_indexer = (function (tree, map) ->
                        match tree with
                           TreeExpression(":", [TreeIdent(label)]) -> (true, StringMap.add label (label ^ ctx) map)
                        | _ -> (false, map)) in
      let lbl_map = tree_hunt lbl_indexer new_tree in
      let find = (function x -> match x with (k, [TreeIdent(label)]) -> if k = ":" or k = "#" then (StringMap.mem label lbl_map) else false | _ -> false) in
      let replace = (function x -> match x with (k, [TreeIdent(label)]) -> (TreeExpression(k,[TreeIdent(StringMap.find label lbl_map)])) | _ -> (raise CantFix)) in
         rewrite new_tree find replace) in
   let inline_indexer = (function (tree, map) ->
                     match tree with
                        TreeExpression("INLINE", [TreeIdent(ident);body]) -> (true, StringMap.add ident body map)
                     | _ -> (false, map)) in
   let macro_map = tree_hunt inline_indexer full_tree in
   let clean_tree = rewrite full_tree (function (name, _) -> name = "INLINE") (function _ -> TreeNoOp) in
   let do_subs (name, children) =
      (let childmap = list_to_childmap children in
         let untranslated = rewrite (StringMap.find name macro_map) (function (id, _) -> (StringMap.mem id childmap)) (function (id, _) -> (StringMap.find id childmap)) in
            fix_labels untranslated (get_ctx ())
      ) in
      rewrite clean_tree (function (name, _) -> StringMap.mem name macro_map) do_subs;;



