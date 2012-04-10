(* main.ml : where the action is
   assemble the script
*)

open Batteries_uni;;
open D16xparse;;
open D16xasm;;
open D16xmacro;;
open D16xcompute;;
open D16xtypes;;
open D16xtable;;

let argv = Array.to_list Sys.argv in
let files = List.filter (function item -> (String.get item 1) != '-') (List.tl argv) in
let show_comments = (List.length (List.filter (function item -> (item = "--debug")) argv)) > 0 in
let staged = parse_files files in
let staged = compile_types staged in
let staged = compile_computes staged in
let staged = compile_tables staged in
let staged = compile_macros staged in
let staged = compile_macros staged in
let machine_code = assemble staged in
   debug_code_print machine_code show_comments

