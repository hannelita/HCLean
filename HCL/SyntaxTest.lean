import HCL.Syntax
import HCL.Types
namespace HCL
open HCL

namespace HCL.SyntaxTest



-- Literal examples
#eval show Literal from .str "hello"
#eval show Literal from .num 42.0
#eval show Literal from .bool true
#eval show Literal from .null

-- Expr examples
#eval show Expr from .lit (.str "world")
#eval show Expr from .var "x"
#eval show Expr from .ref ["module", "foo", "bar"]
#eval show Expr from .func "concat" [ .lit (.str "foo"), .lit (.str "bar") ]
#eval show Expr from .cond (.lit (.bool true)) (.lit (.num 1)) (.lit (.num 2))
#eval show Expr from .listLit [ .lit (.num 1), .lit (.num 2), .lit (.num 3) ]
#eval show Expr from .objLit [ (.lit (.str "foo"), .lit (.num 1)), (.lit (.str "bar"), .lit (.num 2)) ]
#eval show Expr from .attr (.var "obj") "field"
#eval show Expr from .index (.var "xs") (.lit (.num 0))
#eval show Expr from .template [ TemplatePart.text "hello ", TemplatePart.interp (.var "name") ]

-- forList and forObj
#eval show Expr from .forList "x" (.var "xs") (.var "x") none
#eval show Expr from .forObj "k" "v" (.var "objs") (.var "k") (.var "v") none

-- Attribute and BlockType
#eval show Attribute from { name := "foo", value := .lit (.num 42) }
#eval show BlockType from .builtin "resource"
#eval show BlockType from .custom "module"

-- Block and BlockBodyItem
def attr1 : Attribute := { name := "foo", value := .lit (.num 1) }
def attr2 : Attribute := { name := "bar", value := .lit (.str "baz") }
def block1 : Block :=
  { typ := .custom "myblock", labels := ["label1"], body := [ .attr attr1, .attr attr2 ] }

#eval show Block from block1
#eval show BlockBodyItem from .attr attr1
#eval show BlockBodyItem from .block block1

-- RootItem and HCLConfig
#eval show RootItem from .attr attr1
#eval show RootItem from .block block1
#eval show HCLConfig from [ .attr attr1, .block block1 ]

end HCL.SyntaxTest
