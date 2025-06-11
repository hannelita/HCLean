import HCL.Syntax
import HCL.Types
namespace HCL
open HCL
open Except

-- Γ
abbrev Context := List (String × TfType)

def Context.empty : Context := []

def Context.extend (ctx : Context) (name : String) (ty : TfType) : Context :=
  (name, ty) :: ctx

def Context.lookup (ctx : Context) (name : String) : Option TfType :=
  (ctx.find? (fun (n, _) => n == name)).map (·.2)

def Context.contains (ctx : Context) (name : String) : Bool :=
  ctx.any (fun (n, _) => n == name)


-- Type checking
partial def typeCheckExpr (ctx : Context) : Expr → Except String TfType
| Expr.lit lit =>
    match lit with
    | Literal.str _  => .ok TfType.tString
    | Literal.num _  => .ok TfType.tNumber
    | Literal.bool _ => .ok TfType.tBool
    | Literal.null   => .ok TfType.tNull

| Expr.var v =>
    match ctx.find? (fun (name, _) => name = v) with
    | some (_, t) => .ok t
    | none        => .error s!"Unknown variable {v}"

| Expr.ref _ =>
    .error "Reference resolution not implemented"

| Expr.func f args =>
    match f, args with
    | "length", [arg] =>
        let t := typeCheckExpr ctx arg
        match t with
        | .ok (TfType.tList _) => .ok TfType.tNumber
        | .ok _ => .error "length expects a list"
        | .error e => .error e
    | _, _ => .error s!"Unknown function {f}"

| Expr.cond c t e =>
    match typeCheckExpr ctx c with
    | .ok TfType.tBool =>
        match (typeCheckExpr ctx t, typeCheckExpr ctx e) with
        | (.ok tt, .ok te) =>
            if tt == te then .ok tt
            else .error "Branches of conditional must have the same type"
        | (.error e, _) => .error e
        | (_, .error e) => .error e
    | .ok _ => .error "Condition must be boolean"
    | .error e => .error e

| Expr.forList v listExpr bodyExpr maybeCond => do
    let tList ← typeCheckExpr ctx listExpr
    match tList with
    | TfType.tList tElem =>
        let ctx' := (v, tElem) :: ctx
        match maybeCond with
        | some condExpr =>
            let tCond ← typeCheckExpr ctx' condExpr
            unless tCond == TfType.tBool do
              throw s!"forList condition must be boolean, got {tCond}"
        | none => pure ()
        let tBody ← typeCheckExpr ctx' bodyExpr
        .ok (TfType.tList tBody)
    | _ => .error "forList expects a list expression"


| Expr.forObj k v listExpr keyExpr valueExpr maybeCond => do
    let tList ← typeCheckExpr ctx listExpr
    match tList with
    | TfType.tList (TfType.tObject fields) =>
        let ctx' := (k, TfType.tString) :: (v, TfType.tObject fields) :: ctx
        let tKey ← typeCheckExpr ctx' keyExpr
        let tVal ← typeCheckExpr ctx' valueExpr
        match maybeCond with
        | some condExpr =>
            let tCond ← typeCheckExpr ctx' condExpr
            unless tCond == TfType.tBool do
              throw s!"forObj condition must be boolean, got {tCond}"
        | none => pure ()
        .ok (TfType.tObject [("key", tKey), ("value", tVal)])
    | _ => .error "forObj expects a list of objects"

| Expr.objLit kvs => do
    let fieldTypes ← kvs.mapM fun (k, v) => do
      let tk ← typeCheckExpr ctx k
      let tv ← typeCheckExpr ctx v
      match tk with
      | TfType.tString => pure ()
      | _ => throw s!"Object keys must be strings, got {tk}"
      match k with
      | Expr.lit (Literal.str s) => pure (s, tv)
      | _ => throw "Object keys must be string literals"
    .ok (TfType.tObject fieldTypes)

| Expr.listLit xs => do
    let types ← xs.mapM (typeCheckExpr ctx)
    match types with
    | [] => .ok (TfType.tList TfType.tNull)
    | t :: ts =>
        if ts.all (· == t) then .ok (TfType.tList t)
        else .error "Inconsistent types in list"

| Expr.attr e s => do
    let t ← typeCheckExpr ctx e
    match t with
    | TfType.tObject fields =>
        match fields.find? (fun (k, _) => k = s) with
        | some (_, ft) => .ok ft
        | none => .error s!"Attribute {s} not found"
    | _ => .error "Attribute access on non-object"

| Expr.index e i => do
    let tE ← typeCheckExpr ctx e
    let tI ← typeCheckExpr ctx i
    match (tE, tI) with
    | (TfType.tList t, TfType.tNumber) => .ok t
    | _ => .error "Invalid index operation"

| Expr.template parts => do
    -- run the mapM, ignore the list of Unit result, then return TfType.tString
    let _ ← parts.mapM fun
      | TemplatePart.text _ => pure ()
      | TemplatePart.interp e => do
          let t ← typeCheckExpr ctx e
          unless t == TfType.tString ∨ t == TfType.tNumber ∨ t == TfType.tBool do
            throw s!"Invalid interpolation type {t}"
    pure TfType.tString

partial def typeCheckAttribute (ctx : Context) (attr : Attribute) : Except String Context := do
  let _ ← typeCheckExpr ctx attr.value
  -- For now, just return the same context (no new bindings)
  pure ctx

mutual
  partial def typeCheckBlockBodyItem (ctx : Context) : BlockBodyItem → Except String Context
    | BlockBodyItem.attr attr =>
        typeCheckAttribute ctx attr
    | BlockBodyItem.block block =>
        typeCheckBlock ctx block

  partial def typeCheckBlock (ctx : Context) (block : Block) : Except String Context := do
    let mut curCtx := ctx
    for item in block.body do
      curCtx ← typeCheckBlockBodyItem curCtx item
    pure curCtx
end

end HCL
