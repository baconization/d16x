(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

let compile_computes tree =
   (* stackcompute is a very simple algorithm without any kind of trash registers to optimize the computation *)
   let rec stackcompute tree loc highest = (
      let lookup_operator op =
         match op with
            "+" -> (true, "ADD")
         |  "-" -> (true, "SUB")
         |  "*" -> (true, "MUL")
         |  "/" -> (true, "DIV")
         |  "%" -> (true, "MOD")
         | _ -> (false, "") in
      match tree with
         TreeExpression(op, [a;b]) ->
            let (is_op, operand) = lookup_operator op in
            if is_op then
               let eval_a = stackcompute a loc false in
               let eval_b = stackcompute b loc false in
               let x1 = TreeExpression("SET", [loc;TreeIdent("POP")]) in
               let x2 = TreeExpression(operand, [loc;TreeIdent("POP")]) in
               let x3 = if highest then [] else [TreeExpression("SET", [TreeIdent("PUSH");loc])] in
                  TreeExpression("SEQ", [eval_b;eval_a;x1;x2] @ x3)
            else
               TreeExpression("SET", [TreeIdent("PUSH");tree])
      |  _-> TreeExpression("SET", [TreeIdent("PUSH");tree])) in
   let find = function x -> match x with ("stackcompute",[a;b]) -> true | _ -> false in
   let replace = function x -> match x with ("stackcompute",[a;b]) -> stackcompute b a true | _ -> tree in
      rewrite tree find replace;;








