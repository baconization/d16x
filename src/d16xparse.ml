(**
 This file is responsible for turning "(x y)" => (x y)
 That is, this file is responsible for for parsing strings
 into representations that we can manipulate in not-trivial
 and special ways.
 
 The syntax is the purest of all lisp style abstract syntax trees!
**)

open Batteries_uni;;

exception ParseException of string;;

(** TOKENIZATION **)

(* Load a file name while stripping away useless comments and white space and empty lines *)
let load_file filename =
   let rawLines = BatFile.lines_of filename in
   let filteredLines = Enum.map (function rawLine -> 
      let line = BatString.trim rawLine in
      let n = String.length line in
      if n == 0 then
         ""
      else
         if String.get line 0 == '#' then
            ""
         else
            line
      ) rawLines in
   let nonEmptyLines = Enum.filter (function ln -> String.length ln > 0) filteredLines in
   let paddedLines = Enum.map (function ln -> (ln ^ " ")) nonEmptyLines in
      Enum.reduce (function a -> function b -> a ^ b) paddedLines

(* Defines a single token and related meta-data *)
type tyToken = 
     TokOpen
   | TokIdent of string
   | TokNumber of int
   | TokString of string
   | TokClose;;

(* What are we currently processing in our string buffer *)
type bufTyp = BufNone | BufIdent | BufNumber | BufString;;

(* is the character a numeric character *)
let isNumeric chr = '0' <= chr && chr <= '9' || chr == '-' || chr == 'x';;

(* do we consider the character as an identifier *)
let isIdent chr = 
   'a' <= chr && chr <= 'z' ||
   'A' <= chr && chr <= 'Z' ||
   '0' <= chr && chr <= '9' ||
   chr == '_' ||
   chr == '!' ||
   chr == '+' ||
   chr == '-' ||
   chr == '=' ||
   chr == '*' ||
   chr == '/' ||
   chr == ':' ||
   chr == '#';;

let lookupEscapedChar chr = 
   match chr with
      '\\' -> '\\'
   |  'n' -> '\n'
   |  'r' -> '\r'
   |  't' -> '\t'
   |  _ -> raise (ParseException("unknown escape character "^(String.make 1 chr)));;

(* tokenize the char list in reverse *)
let rec rtokenize (charList, typ, stringBuffer, currentTokens) =
   match (charList, typ) with
     ([],_) -> currentTokens
   | ('('::nextCharList, BufNone) -> rtokenize(nextCharList, typ, "", TokOpen :: currentTokens)
   | (')'::nextCharList, BufNone) -> rtokenize(nextCharList, typ, "", TokClose :: currentTokens)
   | (' '::nextCharList, BufNone) -> rtokenize(nextCharList, typ, "", currentTokens)
   | ('\t'::nextCharList, BufNone) -> rtokenize(nextCharList, typ, "", currentTokens)
   | (chr::nextCharList, BufNone) ->
      if isNumeric chr then
         rtokenize(nextCharList, BufNumber, (String.make 1 chr), currentTokens)
      else if chr == '"' then
         rtokenize(nextCharList, BufString, "", currentTokens)
      else if isIdent chr then
         rtokenize(nextCharList, BufIdent, (String.make 1 chr), currentTokens)
      else
         raise (ParseException("unknown character "^(String.make 1 chr)))
   | (chr::nextCharList,BufIdent) ->
      if isIdent chr then
         rtokenize(nextCharList, BufIdent, stringBuffer ^ (String.make 1 chr), currentTokens)
      else
         rtokenize(charList, BufNone, "", TokIdent(stringBuffer) :: currentTokens)
   | (chr::nextCharList,BufNumber) ->
      if isNumeric chr then
         rtokenize(nextCharList, BufNumber, stringBuffer ^ (String.make 1 chr), currentTokens)
      else
         rtokenize(charList, BufNone, "", TokNumber(int_of_string stringBuffer) :: currentTokens)
   | (chr::nextCharList,BufString) -> 
      if chr == '"' then
         rtokenize(nextCharList, BufNone, "", TokString(stringBuffer) :: currentTokens)
      else if chr == '\\' then
         (match nextCharList with
            [] -> raise (ParseException("unexpected end of file"))
         |  escapedChr::remainingCharList ->
            let c = lookupEscapedChar escapedChr in
               rtokenize(remainingCharList, BufString, stringBuffer ^ (String.make 1 c), currentTokens)
         )
      else
         rtokenize(nextCharList, BufString, stringBuffer ^ (String.make 1 chr), currentTokens)
   ;;

(* tokenize the given string *)
let tokenize str =
   let charList = BatString.explode str in
      List.rev (rtokenize (charList, BufNone, "", []))

let rec tokens_to_string_list tokens = 
   match tokens with
     [] -> []
   | TokOpen::t -> "("::(tokens_to_string_list t)
   | TokClose::t -> ")"::(tokens_to_string_list t)
   | TokNumber(n)::t -> (Printf.sprintf "0x%04x" n)::(" "::(tokens_to_string_list t))
   | TokIdent(s)::t -> s::(" "::(tokens_to_string_list t))
   | TokString(s)::t -> "\""::(s::("\" "::(tokens_to_string_list t)))
   ;;

let tokens_to_string tokens = 
   List.reduce (function a -> function b -> a ^ b)  (tokens_to_string_list tokens);;
   
(** TREE PARSING **)
exception ParsingFailed;;

(* primitive tree types *)
type tyTree = 
      TreeInteger of int
   |  TreeString of string
   |  TreeIdent of string
   |  TreeExpression of string*(tyTree list)
   |  TreeNoOp
   ;;
   
let rec tree_to_string tree =
   let foldChildren x = List.reduce (function a -> function b -> a ^ b) (List.map tree_to_string x) in
   match tree with
      TreeInteger(n) -> (Printf.sprintf "0x%04x" n)^" "
   |  TreeString(s) -> "\"" ^ s ^ "\" "
   |  TreeIdent(s) -> s ^ " "
   |  TreeExpression(id, children) -> "(" ^ id ^ " " ^ (foldChildren children) ^ ") "
   |  TreeNoOp -> ""
   ;;
   
let rec parse_tree_item tokens =
   match tokens with
      TokOpen::rest ->
         let (nodeIdent, more) = parse_tree_item rest in
         let ident = (match nodeIdent with TreeIdent(s) -> s | _ -> raise ParsingFailed) in
         let rec processUntilClose moreTokens arr = (
            match moreTokens with
               TokClose::tail -> (arr, tail)
            |  _ ->
               let (subTree, next) = parse_tree_item moreTokens in
                  processUntilClose next (subTree::arr)
         ) in
         let (children, rest) = processUntilClose more [] in
            (TreeExpression(ident, List.rev children), rest)
   |  TokClose::rest -> (TreeInteger(1), rest)
   |  TokNumber(n)::rest -> (TreeInteger(n), rest)
   |  TokIdent(s)::rest -> (TreeIdent(s), rest)
   |  TokString(s)::rest -> (TreeString(s), rest)
   |  [] -> raise ParsingFailed
   ;;

let rec parse_trees tokens =
   let (tree, moreTokens) = parse_tree_item tokens in
      tree::(match moreTokens with [] -> [] | _ -> parse_trees moreTokens);;
   
let parse_root tokens = TreeExpression("SEQ", parse_trees tokens);;

let parse_file filename =
   let script = load_file filename in
   let tokens = tokenize script in
      parse_root tokens;;
      
let parse_files files = TreeExpression("SEQ", List.map parse_file files);;

