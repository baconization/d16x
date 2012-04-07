(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

type tyCompute = Const of int | Expr of string*bool*tyCompute*tyCompute | Value of tyTree;;

(* this encodes our tree structure with enough metadata to simplify the optimization problem *)
let rec pre_formulate_and_compute tree =
   let lookup_operator op =
      match op with
         "+" -> (true, "ADD", true)
      |  "-" -> (true, "SUB", false)
      |  "*" -> (true, "MUL", true)
      |  "/" -> (true, "DIV", false)
      |  "%" -> (true, "MOD", false)
      | _ -> (false, "", false) in
   match tree with
      TreeInteger(n) -> Value(tree)
   |  TreeExpression(op, [a;b]) ->
      let left = pre_formulate_and_compute a in
      let right = pre_formulate_and_compute b in
         (match (op, left, right) with
            ("+", Const(v0), Const(v1)) -> Const(v0 + v1)
         |  ("-", Const(v0), Const(v1)) -> Const(v0 - v1)
         |  ("*", Const(v0), Const(v1)) -> Const(v0 * v1)
         |  ("/", Const(v0), Const(v1)) -> Const(v0 / v1)
         |  _ -> let (is_op, operation, commutes) = lookup_operator op in
            if is_op then
               Expr(operation, commutes, left, right)
            else
               Value(tree))
   |  _ -> Value(tree)
   ;;

let rec next_stack_compute atree loc =
   match atree with
      Const(v) -> TreeExpression("SET", [TreeIdent("PUSH");TreeInteger(v)])
   |  Value(t) -> TreeExpression("SET", [TreeIdent("PUSH");t])
   |  Expr(operation, commutes, left, right) ->
      let eval_left = next_stack_compute left loc in
      let eval_right = next_stack_compute right loc in
      let x1 = TreeExpression("SET", [loc;TreeIdent("POP")]) in
      let x2 = TreeExpression(operation, [loc;TreeIdent("POP")]) in
      let x3 = [TreeExpression("SET", [TreeIdent("PUSH");loc])] in
         TreeExpression("SEQ", [eval_right;eval_left;x1;x2] @ x3)
   ;;

(*
   eventually, I'll introduce this concept
   let trash = [TreeExpression("REG", [TreeIdent("X")]);TreeExpression("REG", [TreeIdent("Y")]);TreeExpression("REG", [TreeIdent("Z")])] in

   where I can pull and put registers/locations so I can optimize the stack utilization
*)

let stackcompute tree loc =
   let atree = pre_formulate_and_compute tree in
   next_stack_compute atree loc;;

let compile_computes tree =
   let find = function x -> match x with ("stackcompute",[a;b]) -> true | _ -> false in
   let replace = function x -> match x with ("stackcompute",[a;b]) -> stackcompute b a | _ -> tree in
      rewrite tree find replace;;





