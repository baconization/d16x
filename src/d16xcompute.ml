(* This defines inline macro expansion *)

open Batteries_uni;;
open D16xparse;;
open D16xutil;;
module StringMap = Map.Make (String);;

type tyCompute = Const of int | Expr of string*bool*tyCompute*tyCompute | Value of tyTree;;

(* Treat this function like a puzzle; it wasn't exactly easy to write, but it
   was a hell of a lot of fun. Now, I understand that I'll not be able to understand
   this next year. Actually, that's a lie, I'm not going to understand it tomorrow.
   But that's ok because I enjoy puzzles *)
let compile_computes tree =
   let make_compute list =
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
         |  TreeExpression(op, [u;v]) ->
            let a = pre_formulate_and_compute u in
            let b = pre_formulate_and_compute v in
               (match (op, a, b) with
                  ("+", Const(v0), Const(v1)) -> Const(v0 + v1)
               |  ("-", Const(v0), Const(v1)) -> Const(v0 - v1)
               |  ("*", Const(v0), Const(v1)) -> Const(v0 * v1)
               |  ("/", Const(v0), Const(v1)) -> Const(v0 / v1)
               |  _ -> let (is_op, operation, commutes) = lookup_operator op in
                  if is_op then
                        Expr(operation, commutes, a, b)
                  else
                     Value(tree))
         |  _ -> Value(tree) in
      let is_register tst =
         match tst with
            TreeExpression("REG", [TreeIdent(x)]) -> (true, tst, x)
         |  _ -> (false, TreeNoOp, "") in
      let join (operation, a, b) temp trash_0 is_trash next =
         let pop_trash trash = (match trash with
               [] -> (false, TreeNoOp, [])
            |  h::t -> (true, h, t)) in
         let opt_x read_x =
            (let (is_reg, _, reg) = is_register read_x in
               if is_reg then (is_trash reg) else false) in
         let (code_b, read_b, trash_b) = next b temp trash_0 is_trash in
         let (code_a, read_a, trash_a) = next a temp trash_b is_trash in
         let is_a_trash = opt_x read_a in
         let (need_pushpop, write_var, x1, trash_x1) = 
            (if is_a_trash then
               (false, read_a, TreeNoOp, trash_a)
            else (
               let (has_trash, new_write, trash_x1) = pop_trash trash_a in
               if has_trash then 
                  (false, new_write, TreeExpression("SET", [new_write;read_a]), trash_x1)
               else
                  (true, temp, TreeExpression("SET", [temp;read_a]) , trash_a)
            )) in
         let x2 = TreeExpression(operation, [write_var; read_b]) in
         let (read_from, x3) =
            (if need_pushpop then
               (TreeIdent("POP"), TreeExpression("SET", [TreeIdent("PUSH"); write_var]))
            else
               (write_var, TreeNoOp)) in
         let is_b_trash = opt_x read_b in
         let trash_x2 = if is_b_trash then read_b::trash_x1 else trash_x1 in
         let code = TreeExpression("SEQ", [code_b;code_a;x1;x2;x3]) in
            (code, read_from, trash_x2) in
      let rec next_stack_compute atree loc trash is_trash =
         match atree with 
            Const(v) -> (TreeNoOp, TreeInteger(v), trash)
         |  Value(t) -> (TreeNoOp, t, trash)
         |  Expr(operation, can_commute, a, b) ->
            let chk_x x = 
               (let (_, test_x, _) = next_stack_compute x loc trash is_trash in 
               let (is_reg_x, _, reg_x) = is_register test_x in
                  (is_reg_x, reg_x)) in
            let (is_reg_a, reg_a) = chk_x a in
            let (is_reg_b, reg_b) = chk_x b in
            (* todo: this should be removed, in favor that does a full commutative tree collapse/refactor *)
            let should_swap = can_commute  && (not is_reg_a) && is_reg_b && (is_trash reg_b)  in 
            let (u, v) = if should_swap then (b, a) else (a, b) in
               join (operation, u, v) loc trash is_trash next_stack_compute in
      let do_compute tree loc trash =
         let weave tree loc trash =
            let trash_selector = (function (item, map) -> match item with TreeIdent(reg) -> (true, StringMap.add reg true map) | _ -> (false, map)) in
            let trash_map = tree_hunt trash_selector (TreeExpression("SEQ", trash)) in
            let is_trash = (function item -> StringMap.mem item trash_map) in
            let atree = pre_formulate_and_compute tree in
            let (code, read, _) = next_stack_compute atree loc trash is_trash in
               (code, read) in
         let (code, read) = weave tree loc trash in
            if code = TreeNoOp then
               (TreeExpression("SET",[loc;read]))
            else
               if read = TreeIdent("POP") then
                  TreeExpression("SEQ", [code;TreeExpression("SET", [loc;read])])
               else
                  let (is_reg, _, _) = is_register read in
                  (if (loc = read) or (not is_reg) then
                     code
                  else
                     let new_loc = read in
                     let new_trash = List.map (function item -> if item = new_loc then loc else item) trash in
                     let (new_code, new_read) = weave tree new_loc new_trash in
                        new_code) in
      let temp = List.hd list in
      let all = List.rev (List.tl list) in
      let body = List.hd all in
      let trash = List.tl all in
         do_compute body temp trash in
   let find = function x -> match x with ("compute",l) -> (List.length l) > 1 | _ -> false in
   let replace = function x -> match x with ("compute",l) -> make_compute l | _ -> tree in
      rewrite tree find replace;;

