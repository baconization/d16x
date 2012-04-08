(**
 This file is responsible for turning simplified abstract syntax trees
 into machine code as a series of words.
**)

open Batteries_uni;;
open D16xparse;;
module StringMap = Map.Make (String);;

exception Unknown of string;;

(* this basically defines the machine code *)
type tyWord = 
      Word of int (* a raw word *)
   |  DefineLabel of string (* this isn't a word, it's just a marker to store the position of the next word *)
   |  LabelLookup of string (* this is going to become a word, but now it's a hole that we plan to fill later *)
   |  Comment of string*int (* this isn't a word, it's just text that we hold onto for debugging purposes *)
   ;;

(* assemble the most basic of instructions *)
let rec assemble_untranslated_machine_code tree =
   let rec assemble_op (oper, a, b, c) =
      let operation_value opcode =
         (match opcode with
            "SET" -> 0x1 | "ADD" -> 0x2 | "SUB" -> 0x3 | "MUL" -> 0x4
         |  "DIV" -> 0x5 | "MOD" -> 0x6 | "SHL" -> 0x7 | "SHR" -> 0x8
         |  "AND" -> 0x9 | "BOR" -> 0xa | "XOR" -> 0xb | "IFE" -> 0xc
         |  "IFN" -> 0xd | "IFG" -> 0xe | "IFB" -> 0xf
         |  "0" -> 0x0
         | _ -> raise (Unknown(opcode))) in
      let rec assemble_value tree =
         let register_table ident =
            (match ident with
               "A" -> 0x00 | "B" -> 0x01 | "C" -> 0x02 | "X" -> 0x03
            |  "Y" -> 0x04 | "Z" -> 0x05 | "I" -> 0x06 | "J" -> 0x07
            |  _ -> raise (Unknown(ident))) in
         (match tree with
            TreeInteger(n) ->
               if n < 0 then 
                  raise (Unknown("negatives not supported yet"))
               else if n <= 0x1f then 
                  (n + 0x20, [])
               else
                  (0x1f, [Word(n)])
         |  TreeExpression("OP", [TreeInteger(op)]) -> (op, [])
         |  TreeExpression("REG", [TreeIdent(reg)]) -> (register_table(reg), [])
         |  TreeExpression("AT", [TreeIdent(reg)]) -> (0x08 + register_table(reg), [])
         |  TreeExpression("AT", [TreeInteger(pos)]) -> (0x1e, [Word(pos)])
         |  TreeExpression("AT", [TreeIdent(reg); TreeInteger(offset)]) -> (0x10 + register_table(reg), [Word(offset)])
         |  TreeExpression("AT", [TreeInteger(offset); TreeIdent(reg)]) -> (0x10 + register_table(reg), [Word(offset)])
         |  TreeExpression("#", [TreeIdent(lbl)]) -> (0x1f, [LabelLookup(lbl)])
         |  TreeIdent("POP") -> (0x18, [])
         |  TreeIdent("PEEK") -> (0x19, [])
         |  TreeIdent("PUSH") -> (0x1a, [])
         |  TreeIdent("SP") -> (0x1b, [])
         |  TreeIdent("PC") -> (0x1c, [])
         |  TreeIdent("EX") -> (0x1d, [])
         |  _ -> raise (Unknown("unknown value got: " ^ (tree_to_string tree)))) in
      let (va, wa) = assemble_value a in
      let (vb, wb) = assemble_value b in
      let op = operation_value oper in
      let words = [Word(vb * 16 * 64 + va * 16 + op)] @ wa @ wb in
         words @ [Comment(c, List.length words)] in
   let assemble_extended_op op v comment = (* todo: update for new 7-bit op-code *)
      assemble_op ("0", TreeExpression("OP",[TreeInteger(op)]), v, comment) in
   match tree with
      TreeExpression("SEQ", children) -> List.flatten (List.map assemble_untranslated_machine_code children)
   |  TreeExpression("WORD", [TreeInteger(w)]) -> [Word(w); Comment("Word " ^ (string_of_int w), 1)]
   |  TreeExpression("DATA", d) ->
         let f = (function x -> match x with TreeInteger(w) -> Word(w) | _ -> raise (Unknown("unknown tree;"))) in 
            (List.map f d) @ [Comment("DATA ...", List.length d)]
   |  TreeExpression("EXT", [TreeInteger(op);v]) -> assemble_extended_op op v (tree_to_string tree)
   |  TreeExpression("JSR", [v]) -> assemble_extended_op 0x1 v (tree_to_string tree)
   |  TreeExpression(":", [TreeIdent(ident)]) -> [DefineLabel(ident)]
   |  TreeExpression(binaryOp, [a;b]) ->
      let comment = tree_to_string tree in
         assemble_op (binaryOp, a, b, comment)
   |  TreeNoOp -> []
   |  _ -> raise (Unknown("unknown tree;"))
   ;;
      
(* given a very basic tree, assemble the machine code *)
let assemble code =
   let translate_machine_code code =
      let rec build code map at =
         (match code with
            Word(word)::moreCode -> build moreCode map (at + 1)
         |  DefineLabel(ident)::moreCode -> build moreCode (StringMap.add ident at map) at
         |  LabelLookup(x)::moreCode -> build moreCode map (at + 1)
         |  Comment(_)::moreCode -> build moreCode map at
         |  [] -> map) in
      let map = build code StringMap.empty 0 in
      let subs = function item -> match item with LabelLookup(ident) -> Word(StringMap.find ident map) | _ -> item in
      let rlabel = (function item -> match item with DefineLabel(_) -> false | _ -> true) in
      let resolved = List.map subs code in
         List.filter rlabel resolved in
   translate_machine_code (assemble_untranslated_machine_code code);;

(* debug the machine code *)
let debug_code_print code show_comments =
   let debugging_machine_code_printer item =
      (match item with
         Word(word) -> print_string (Printf.sprintf "%04x" word)
      |  DefineLabel(ident) -> print_string (ident ^ ":\n")
      |  LabelLookup(x) -> print_string x
      |  Comment(x,tab) ->
         if show_comments then
            print_string ((String.make (20-4*tab) ' ') ^ ";" ^ x ^ "\n")
         else
            print_string "\n"
      ) in
   List.map debugging_machine_code_printer code;;
   
