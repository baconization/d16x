(* main.ml : where the action is
   assemble the script
*)

open Batteries_uni;;
open D16xparse;;
open D16xasm;;

let argv = Array.to_list Sys.argv in
let files = List.filter (function item -> (String.get item 1) != '-') (List.tl argv) in
let show_comments = (List.length (List.filter (function item -> (item = "--debug")) argv)) > 0 in
let machine_code = assemble (parse_files files) in
   debug_code_print machine_code show_comments

