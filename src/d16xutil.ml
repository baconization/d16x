(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
module StringMap = Map.Make (String);;

(* convert a list into a StringMap *)
let list_to_childmap list =
   let rec build list idx map =
      (match list with
            [] -> map
         |  h::t ->
            let key = ("$" ^ (string_of_int idx)) in
            let submap = StringMap.add key h map in
               build t (idx + 1) submap
      ) in
   build list 1 StringMap.empty
   ;;

(* this fun little guy lets you hunt for things in the tree and build a map *)
let tree_hunt indexer tree =
   let rec hunter map tree =
      (let (found, nextmap) = indexer (tree, map) in
         if found then
            nextmap
         else (match tree with
            TreeExpression(_,children) -> List.fold_left hunter nextmap children
         |  _ -> nextmap)) in
      hunter StringMap.empty tree;;

(* this is the core algorithm for doing fancy rewriting *)
let rewrite tree predicate foo =
   let rec subs t =
      (match t with
         TreeIdent(k) ->
            if predicate (k, []) then
               foo (k, [])
            else
               t   
      |  TreeExpression(k, c) ->
            if predicate (k, c) then 
               foo (k, c)
            else
               TreeExpression(k, List.map subs c)
      |  _ -> t) in
   subs tree;;
