%{

open Ast

%}
%token <string> LITERAL
%token <string> CHAR
%token <string> DATA
%token <string> PROPERTY
%token DOUBLE_AMPERSAND
%token DOUBLE_BAR
%token BAR
%token LEFT_BRACKET
%token RIGHT_BRACKET
%token ASTERISK
%token PLUS
%token QUESTION_MARK
%token <[ `Comma | `Space ] * int * int option> RANGE
%token EXCLAMATION_POINT
%token LEFT_PARENS
%token RIGHT_PARENS
%token EOF

%start <Ast.value option> value_of_lex
%start <Ast.multiplier option> multiplier_of_lex
%%

let value_of_lex :=
  | EOF; { None }
  | v = value; EOF; { Some v }

let multiplier_of_lex :=
  | EOF; { None }
  | m = multiplier; EOF; { Some m }

let multiplier :=
  | ASTERISK; // *
    { Zero_or_more }
  | PLUS; // +
    { One_or_more }
  | QUESTION_MARK; // ?
    { Optional }
  | r = RANGE; // 1..4
    {
      match r with
      | (`Space, min, max) -> Repeat (min, max)
      | (`Comma, min, max) -> Repeat_by_comma (min, max)
    }
  | EXCLAMATION_POINT; // !
    { At_least_one }

let terminal ==
  | c = CHAR; { Delim c } // 'a'
  | l = LITERAL; { Keyword l } // "absolute"
  | d = DATA; { Data_type d } // <color>
  | p = PROPERTY; { Property_type p } // <'border'>

let terminal_multiplier(terminal) ==
  | t = terminal; { Terminal(t, One) } // "important"
  | t = terminal; m = multiplier; { Terminal(t, m) } // "important?"

let function_call :=
  | terminal_multiplier(terminal)
  | l = LITERAL; LEFT_PARENS; v = value; RIGHT_PARENS; { Function_call(l, v) } // rgb(1,2,3)

let group :=
  | function_call
  | LEFT_BRACKET; v = value; RIGHT_BRACKET; { v } // [ v ]
  | LEFT_BRACKET; v = value; RIGHT_BRACKET; m = multiplier; { Group(v, m) } // [ v ]!

let combinator(sep, sub, kind) ==
  | vs = separated_nonempty_list(sep, sub); ~ = kind;
    { match vs with | v::[] -> v | vs -> Combinator(kind, vs) }

let static_expr ==
  | combinator(| {}, group, | { Static }) // A B
let and_expr ==
  | combinator(DOUBLE_AMPERSAND, static_expr, | { And }) // A && B
let or_expr ==
  | combinator(DOUBLE_BAR, and_expr, | { Or }) // A || B
let xor_expr ==
  | combinator(BAR, or_expr, | { Xor }) // A | B

let value :=
  | xor_expr
  (* TODO: this is clearly a workaround *)
  | terminal_multiplier(| RIGHT_PARENS; { Keyword ")" } | LEFT_PARENS; { Keyword "(" })
