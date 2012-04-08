(* typing and memory layout stuff *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

type tyType = Word | WordArray of int | Array of string * int | Pointer of string | Struct of (string list)*(string -> tyType) | Ref of string;;

exception StrutureBorked;;

let rec build_type tree =
   let build_struct name members resolve = 
      let ex = (function member -> match member with TreeExpression(member_name,[ty]) -> (ty, member_name) | _ -> raise StrutureBorked) in
      let membership = List.map ex members in
      let builder = (function map -> function (ty, nme) -> StringMap.add nme (resolve ty) map) in
      let get_domain = (function (ty, nme) -> nme) in
      let final_map = List.fold_left builder StringMap.empty membership in
      let domain = List.map get_domain membership in
      let lookup = function key -> (StringMap.find key final_map) in
         Struct(domain, lookup) in
   match tree with
      TreeExpression("word", []) -> Word
   |  TreeIdent("word") -> Word
   |  TreeExpression("array", [TreeIdent("word"); TreeInteger(n)]) -> WordArray(n)
   |  TreeExpression("array", [TreeIdent(ty); TreeInteger(n)]) -> Array(ty,n)
   |  TreeExpression("ptr", [TreeIdent(ty)]) -> Pointer(ty)
   |  TreeExpression("struct", TreeIdent(name)::children) -> build_struct name children build_type
   |  TreeIdent(name) -> Ref(name)
   | _ -> raise StrutureBorked
   ;;

exception NotFound;;

let rec sizeof (typ,finder) =
   let s_sizeof str =
      sizeof ((finder str), finder) in
   match typ with
      Word -> 1
   |  WordArray(n) -> n
   |  Array(sty, n) -> n * s_sizeof sty
   |  Pointer(_) -> 1
   |  Ref(sty) -> s_sizeof sty
   |  Struct(domain, lookup) ->
         let sizes = List.map (function key -> sizeof ((lookup key), finder)) domain in
         List.fold_left (function a -> function b -> a + b) 0 sizes;;

let rec offset domain lookup search finder at =
   match domain with
      [] -> raise NotFound
   |  inspect::more ->
      if inspect = search then
         at
      else
         let next_at = (at + (sizeof (lookup inspect, finder))) in
         offset more lookup search finder next_at;;

let compile_types tree =
   let index_structs tree =
      let add = StringMap.add in
      let indexer = function (x, map) -> match x with TreeExpression("struct", TreeIdent(name)::c) -> (true, add name (build_type x) map) | _ -> (false, map) in
         tree_hunt indexer tree in
   let struct_map = index_structs tree in
   let find_struct name = StringMap.find name struct_map in
   let remove_structs tree =
      let find = function (name,_) -> name = "struct" in
      let replace = function _ -> TreeNoOp in
         rewrite tree find replace in
   let tree_without_structs = remove_structs tree in
   let rewrite_sizes tree =
      let find = function (name,_) -> name = "sizeof" in
      let replace_meat = function def -> TreeInteger(sizeof (find_struct def,find_struct)) in
      let replace = (function (name, lookup) -> match lookup with [TreeIdent(def)] -> replace_meat def | _ -> (raise StrutureBorked)) in
         rewrite tree find replace in
   let rewritten_sizeof = rewrite_sizes tree_without_structs in
   let rewrite_offset tree =
      let find = function (name,_) -> name = "offset" in
      let replace_meat = function (stct,fld)  -> 
         let ty = find_struct stct in
         let (domain, lookup) = match ty with Struct(domain, lookup) -> (domain, lookup) | _ -> raise StrutureBorked in
         let calc = offset domain lookup fld find_struct 0 in
            TreeInteger(calc) in
      let replace = (function (name, lookup) -> match lookup with [TreeIdent(stct); TreeIdent(fld)] -> replace_meat (stct, fld) | _ -> (raise StrutureBorked)) in
         rewrite tree find replace in
   rewrite_offset rewritten_sizeof
   ;;

