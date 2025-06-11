import HCL.Syntax
import HCL.Types
import HCL.Typing
namespace HCL
open HCL

-- Example 1: Literal expressions
#eval HCL.typeCheckExpr [] (HCL.Expr.lit (HCL.Literal.str "hello"))  -- .ok tString
#eval HCL.typeCheckExpr [] (HCL.Expr.lit (HCL.Literal.num 42))      -- .ok tNumber
#eval HCL.typeCheckExpr [] (HCL.Expr.lit (HCL.Literal.bool true))   -- .ok tBool

-- Example 2: Variable lookup
#eval HCL.typeCheckExpr [("x", HCL.TfType.tNumber)] (HCL.Expr.var "x")  -- .ok tNumber
#eval HCL.typeCheckExpr [] (HCL.Expr.var "y")                           -- .error "Unknown variable y"

-- Example 3: List literal with consistent types
#eval HCL.typeCheckExpr [] (HCL.Expr.listLit [
  HCL.Expr.lit (HCL.Literal.num 1),
  HCL.Expr.lit (HCL.Literal.num 2)
])  -- .ok (tList tNumber)

-- Example 4: List literal with inconsistent types
#eval HCL.typeCheckExpr [] (HCL.Expr.listLit [
  HCL.Expr.lit (HCL.Literal.num 1),
  HCL.Expr.lit (HCL.Literal.str "oops")
])  -- .error "Inconsistent types in list"

-- Example 5: Object literal
#eval HCL.typeCheckExpr [] (HCL.Expr.objLit [
  (HCL.Expr.lit (HCL.Literal.str "foo"), HCL.Expr.lit (HCL.Literal.num 1)),
  (HCL.Expr.lit (HCL.Literal.str "bar"), HCL.Expr.lit (HCL.Literal.num 2))
])  -- .ok (tObject [("foo", tNumber), ("bar", tNumber)])

-- Example 6: Attribute access
#eval HCL.typeCheckExpr [] (
  HCL.Expr.attr
    (HCL.Expr.objLit [
      (HCL.Expr.lit (HCL.Literal.str "foo"), HCL.Expr.lit (HCL.Literal.num 1))
    ])
    "foo"
)  -- .ok tNumber

-- Example 7: Conditional
#eval HCL.typeCheckExpr [] (
  HCL.Expr.cond
    (HCL.Expr.lit (HCL.Literal.bool true))
    (HCL.Expr.lit (HCL.Literal.num 1))
    (HCL.Expr.lit (HCL.Literal.num 2))
)  -- .ok tNumber

-- Example 8: forList
#eval HCL.typeCheckExpr [] (
  HCL.Expr.forList "x"
    (HCL.Expr.listLit [HCL.Expr.lit (HCL.Literal.num 1), HCL.Expr.lit (HCL.Literal.num 2)])
    (HCL.Expr.var "x")
    none
)  -- .ok (tList tNumber)
