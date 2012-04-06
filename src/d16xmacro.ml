(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
module StringMap = Map.Make (String);;


let rec compile_macros full_tree =
   let rec build tree map = (
      let rec build_children list submap =
         (match list with
            [] -> submap
         | h::t -> let nextmap = build h submap in build_children t nextmap) in
      match tree with
         TreeExpression("INLINE", [TreeIdent(ident);body]) -> StringMap.add ident body map
      |  TreeExpression(_,children) -> build_children children map
      |  _ -> map
   ) in
   let macro_map = build full_tree StringMap.empty in
   let rec rewrite_macros tree =
      (match tree with
         TreeExpression("INLINE", _) -> TreeNoOp
      |  TreeExpression(ident, children) ->
            if StringMap.mem ident macro_map then
               StringMap.find ident macro_map
            else
               TreeExpression(ident, List.map rewrite_macros children)
      |  _ -> tree) in
   rewrite_macros full_tree;;
