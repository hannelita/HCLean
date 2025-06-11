namespace HCL

inductive Literal
| str   : String → Literal
| num   : Float → Literal
| bool  : Bool → Literal
| null  : Literal
deriving Repr, BEq

mutual
  inductive Expr
  | lit     : Literal → Expr
  | var     : String → Expr
  | ref     : List String → Expr
  | func    : String → List Expr → Expr
  | cond    : Expr → Expr → Expr → Expr
  | forList : String → Expr → Expr → Option Expr → Expr
  | forObj  : String → String → Expr → Expr → Expr → Option Expr → Expr
  | objLit  : List (Expr × Expr) → Expr
  | listLit : List Expr → Expr
  | attr    : Expr → String → Expr
  | index   : Expr → Expr → Expr
  | template : List TemplatePart → Expr
  deriving Repr, BEq

  inductive TemplatePart
  | text : String → TemplatePart
  | interp : Expr → TemplatePart
  deriving Repr, BEq
end

structure Attribute where
  name : String
  value : Expr
deriving Repr, BEq

inductive BlockType
| builtin : String → BlockType
| custom  : String → BlockType
deriving Repr, BEq

mutual
  structure Block where
    typ     : BlockType
    labels  : List String
    body    : List BlockBodyItem
  deriving Repr, BEq

  inductive BlockBodyItem
  | attr : Attribute → BlockBodyItem
  | block : Block → BlockBodyItem
  deriving Repr, BEq
end

inductive RootItem
| attr : Attribute → RootItem
| block : Block → RootItem
deriving Repr, BEq

abbrev HCLConfig := List RootItem

end HCL

open HCL
#eval show Expr from .lit (.str "hello")
#eval show Expr from .func "concat" [ .lit (.str "foo"), .lit (.str "bar") ]
#eval show BlockType from .custom "module"

def testExpr : Expr :=
  Expr.func "length" [Expr.listLit [Expr.lit (Literal.num 1), Expr.lit (Literal.num 2)]]

#eval testExpr  -- prints the expression using the Repr instance
