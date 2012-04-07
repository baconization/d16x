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
      TreeInteger(n) -> Const(n)
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
      Const(v) -> 
         (TreeNoOp, TreeInteger(v))
   |  Value(t) ->
         let code = TreeExpression("SET", [TreeIdent("PUSH");t]) in
         let read = TreeIdent("POP") in
            (code, read)
   |  Expr(operation, commutes, left, right) ->
      let (code_left, read_left) = next_stack_compute left loc in
      let (code_right, read_right) = next_stack_compute right loc in
      let x1 = TreeExpression("SET", [loc;read_left]) in
      let x2 = TreeExpression(operation, [loc;read_right]) in
      let x3 = [TreeExpression("SET", [TreeIdent("PUSH");loc])] in
      let code = TreeExpression("SEQ", [code_right;code_left;x1;x2] @ x3) in
      let read = TreeIdent("POP") in
         (code, read)
   ;;

(*
   eventually, I'll introduce this concept
   let trash = [TreeExpression("REG", [TreeIdent("X")]);TreeExpression("REG", [TreeIdent("Y")]);TreeExpression("REG", [TreeIdent("Z")])] in

   where I can pull and put registers/locations so I can optimize the stack utilization
*)

let stackcompute tree loc =
   let atree = pre_formulate_and_compute tree in
   let (code, read) = next_stack_compute atree loc in
      if code = TreeNoOp then
         TreeExpression("SET", [loc; read])
      else
         TreeExpression("SEQ", [code; TreeExpression("SET", [loc; read])]);;

let compile_computes tree =
   let find = function x -> match x with ("stackcompute",[a;b]) -> true | _ -> false in
   let replace = function x -> match x with ("stackcompute",[a;b]) -> stackcompute b a | _ -> tree in
      rewrite tree find replace;;





