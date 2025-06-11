import HCL.Syntax
namespace HCL
open HCL
open Except


inductive TfType
| tString : TfType
| tNumber : TfType
| tBool   : TfType
| tNull   : TfType
| tList   : TfType → TfType
| tObject : List (String × TfType) → TfType
deriving Repr, BEq

partial def tfTypeToString : TfType → String
| TfType.tString         => "string"
| TfType.tNumber         => "number"
| TfType.tBool           => "bool"
| TfType.tNull           => "null"
| TfType.tList inner     => "list(" ++ tfTypeToString inner ++ ")"
| TfType.tObject fields  =>
    let fieldStrs := fields.map (fun (name, ty) => name ++ " = " ++ tfTypeToString ty)
    "object({" ++ String.intercalate ", " fieldStrs ++ "})"

instance : ToString TfType where
  toString := tfTypeToString

end HCL
