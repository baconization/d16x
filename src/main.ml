(* main.ml : where the action is
   assemble the script
*)

open Batteries_uni;;
open D16xparse;;
open D16xasm;;
open D16xmacro;;
open D16xcompute;;
open D16xtypes;;

let argv = Array.to_list Sys.argv in
let files = List.filter (function item -> (String.get item 1) != '-') (List.tl argv) in
let show_comments = (List.length (List.filter (function item -> (item = "--debug")) argv)) > 0 in
let stage1 = parse_files files in
let stage2 = compile_types stage1 in
let stage3 = compile_computes stage2 in
let stage4 = compile_macros stage3 in
let machine_code = assemble stage4 in
   debug_code_print machine_code show_comments

