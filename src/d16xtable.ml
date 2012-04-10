(* makes building tables and word to word maps easy *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

exception TableWTF;;

(* as we need to inject labels, this will generate them for us *)
let tbl_cell_counter = ref 0;;
let get_cell typ =
   tbl_cell_counter := !tbl_cell_counter + 1; ("jump_" ^ typ ^ "_" ^ (string_of_int(!tbl_cell_counter)));;

(* slow, but space efficient *)
let slow_replace input output fixed =
   let code_up = function (_, test, v) -> [TreeExpression("IFE",[input;test]); TreeExpression("SET",[output;v])] in
   let code = (List.flatten (List.map code_up fixed)) in
      TreeExpression("SEQ", code);;

(* fast, but uses more space *)
let fast_replace input output fixed =
   let inner_fast_replace big_list input output end_label =
      let find_split raw_list =
         let list = List.map (function (x,_,_) -> x) raw_list in
         let min = List.fold_left (function a -> function b -> if a < b then a else b) (List.hd list) list in
         let max = List.fold_left (function a -> function b -> if a > b then a else b) (List.hd list) list in
            (min + max) / 2 in
      let partition list =
         let split_at = find_split list in
            List.partition (function (v, _, _) -> v <= split_at) list in
      let rec inner list is_right = 
         let gotoend = TreeExpression("#", [TreeIdent(end_label)]) in
         let code_to_gotoend = if is_right then TreeNoOp else TreeExpression("SET", [TreeIdent("PC");gotoend]) in
         match list with
            [(_, test, v)] -> [TreeExpression("IFE",[input;test]); TreeExpression("SET",[output;v]); code_to_gotoend ]
         |   [(_, test1, v1);(_, test2, v2)] -> 
            [ TreeExpression("IFE",[input;test1]); TreeExpression("SET",[output;v1]);
              TreeExpression("IFE",[input;test2]); TreeExpression("SET",[output;v2]); code_to_gotoend
            ]
         | _ ->
               let (left, right) = partition list in
               let ati = (((function (v,_,_) -> v) (List.hd right)) - 1) in
               let at = TreeInteger(ati) in
               let mid_label = (get_cell ("fast_mid_" ^ (string_of_int ati))) in
               let mid_code = [TreeExpression(":", [TreeIdent(mid_label)])] in
               let goto_mid =  TreeExpression("#", [TreeIdent(mid_label)]) in
               let jump_ahead = [TreeExpression("IFG", [input;at]) ; TreeExpression("SET",[TreeIdent("PC");goto_mid])] in
                  jump_ahead @ (inner left false) @ mid_code @ (inner right is_right)
         in inner big_list true in
   let end_label = get_cell "fast_end" in
   let end_code = [TreeExpression(":", [TreeIdent(end_label)])] in
   let code = (inner_fast_replace fixed input output end_label) @ end_code in
      TreeExpression("SEQ", code);;

let compile_tables tree =
   let extract_from_to item =
      match item with
         TreeExpression("element", [TreeInteger(src);v]) -> (src, TreeInteger(src),v)
      |  TreeExpression("e", [TreeInteger(src);v]) -> (src,TreeInteger(src),v)
      |  _ -> raise TableWTF in
   let fix_up children = 
      let fixed = List.map extract_from_to children in
      let cmp = (function (a,_,_) -> function (b,_,_) -> a - b) in
         List.stable_sort cmp fixed in
   let replace_meat algo input output children =
      let fixed = fix_up children in
         if algo = "slow" or algo = "compact" then
            slow_replace input output fixed
         else
            fast_replace input output fixed in
   let find = (function (name,_) -> name = "table") in
   let replace = (function (name, t) -> match t with (TreeIdent(algo))::(src::(dest::children)) -> (replace_meat algo src dest children) | _ -> (raise TableWTF)) in
      rewrite tree find replace
   ;;

