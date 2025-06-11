import HCL.Syntax
import HCL.Types
import HCL.Typing

namespace HCL
open HCL

class ToSMT (α : Type) where
  toSMT : α → String


-- Literal → SMT
instance : ToSMT Literal where
  toSMT
    | Literal.str s  => "\"" ++ s ++ "\""
    | Literal.num n  => toString n
    | Literal.bool b => if b then "true" else "false"
    | Literal.null   => "null"

-- TfType → SMT Sort
def tfTypeToSMTSort : TfType → String
  | TfType.tString       => "String"
  | TfType.tNumber       => "Real"
  | TfType.tBool         => "Bool"
  | TfType.tNull         => "HCLNull"
  | TfType.tList t       => "(List " ++ tfTypeToSMTSort t ++ ")"
  | TfType.tObject kvs   =>
      let rec fieldsToStr : List (String × TfType) → List String
        | [] => []
        | (k, v) :: rest => ("(" ++ k ++ " " ++ tfTypeToSMTSort v ++ ")") :: fieldsToStr rest
      "(HCLObj " ++ String.intercalate " " (fieldsToStr kvs) ++ ")"

instance : ToSMT TfType where
  toSMT := tfTypeToSMTSort

-- Expr → SMT (initial stub)
partial def exprToSMT : Expr → String
  | Expr.lit lit => ToSMT.toSMT lit
  | Expr.var name => name
  | Expr.ref path => String.intercalate "." path
  | Expr.func f args =>
      let argStrs := args.map exprToSMT
      "(" ++ f ++ " " ++ String.intercalate " " argStrs ++ ")"
  | Expr.cond c t e =>
      "(ite " ++ exprToSMT c ++ " " ++ exprToSMT t ++ " " ++ exprToSMT e ++ ")"
  | Expr.listLit xs =>
      "(list " ++ String.intercalate " " (xs.map exprToSMT) ++ ")"
  | Expr.objLit fields =>
      let entries := fields.map (fun (k, v) => "(" ++ exprToSMT k ++ " " ++ exprToSMT v ++ ")")
      "(object " ++ String.intercalate " " entries ++ ")"
  | Expr.attr obj attr =>
      "(get-attr " ++ exprToSMT obj ++ " " ++ attr ++ ")"
  | Expr.index arr i =>
      "(select " ++ exprToSMT arr ++ " " ++ exprToSMT i ++ ")"
  | Expr.template parts =>
      let s := parts.map (fun
        | TemplatePart.text t   => "\"" ++ t ++ "\""
        | TemplatePart.interp e => exprToSMT e)
      "(concat " ++ String.intercalate " " s ++ ")"
  | Expr.forList name coll body condOpt =>
      let base := "(map (λ (" ++ name ++ ") " ++ exprToSMT body ++ ") " ++ exprToSMT coll ++ ")"
      match condOpt with
      | none   => base
      | some c => "(filter (λ (" ++ name ++ ") " ++ exprToSMT c ++ ") " ++ base ++ ")"
  | Expr.forObj k v coll keyExpr valExpr condOpt =>
    let base := "(map-obj (λ (" ++ k ++ " " ++ v ++ ") (pair " ++ exprToSMT keyExpr ++ " " ++ exprToSMT valExpr ++ ")) " ++ exprToSMT coll ++ ")"
    match condOpt with
    | none   => base
    | some c => "(filter-obj (λ (" ++ k ++ " " ++ v ++ ") " ++ exprToSMT c ++ ") " ++ base ++ ")"


instance : ToSMT Expr where
  toSMT := exprToSMT

instance : ToSMT Attribute where
  toSMT a :=
    "(attr " ++ a.name ++ " " ++ ToSMT.toSMT a.value ++ ")"

def toSMTAttribute (attr : Attribute) : String :=
  "(attr " ++ attr.name ++ " " ++ ToSMT.toSMT attr.value ++ ")"  -- assuming you have toSMTExpr

mutual
  partial def toSMTBlockBodyItem (bbi : BlockBodyItem) : String :=
    match bbi with
    | BlockBodyItem.attr attr => toSMTAttribute attr
    | BlockBodyItem.block b   => toSMTBlock b

  partial def toSMTBlock (b : Block) : String :=
    let blockType :=
      match b.typ with
      | BlockType.builtin t => t
      | BlockType.custom t  => t
    let labelStr := if b.labels.isEmpty then "" else " " ++ String.intercalate " " b.labels
    let bodyStr :=
      String.intercalate "\n  " (b.body.map toSMTBlockBodyItem)
    "(block " ++ blockType ++ labelStr ++ "\n  " ++ bodyStr ++ ")"
end

instance : ToSMT BlockBodyItem where
  toSMT bbi := toSMTBlockBodyItem bbi

instance : ToSMT Block where
  toSMT b := toSMTBlock b

instance : ToSMT RootItem where
  toSMT
    | RootItem.attr a => ToSMT.toSMT a
    | RootItem.block b => ToSMT.toSMT b

end HCL
