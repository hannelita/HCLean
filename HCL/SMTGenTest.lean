import HCL.Syntax
import HCL.Types
import HCL.Typing
import HCL.SMTGen


open Std

namespace HCL
open HCL


#eval ToSMT.toSMT (Expr.var "foo")            -- ⇒ "foo"
#eval ToSMT.toSMT TfType.tString              -- ⇒ "String"
#eval ToSMT.toSMT (Literal.num 42.0)          -- ⇒ "42.0"



def exampleBlock : Block :=
  {
    typ := BlockType.builtin "resource",
    labels := ["aws_instance", "web_server"],
    body := [
      BlockBodyItem.attr {
        name := "ami",
        value := Expr.ref ["data", "aws_ami", "ubuntu", "id"]
      },
      BlockBodyItem.attr {
        name := "instance_type",
        value := Expr.var "var.instance_type"
      },
      BlockBodyItem.attr {
        name := "tags",
        value := Expr.objLit [
          (Expr.lit (Literal.str "Name"), Expr.var "local.project_name_web_server"),
          (Expr.lit (Literal.str "Environment"), Expr.lit (Literal.str "Development"))
        ]
      }
    ]
  }

#eval toSMTBlock exampleBlock


def awsRegionVariableBlock : Block :=
  { typ := BlockType.builtin "variable",
    labels := ["aws_region"],
    body := [
      BlockBodyItem.attr {
        name := "description",
        value := Expr.lit (Literal.str "The AWS region to deploy resources in.")
      },
      BlockBodyItem.attr {
        name := "type",
        value := Expr.var "string"
      },
      BlockBodyItem.attr {
        name := "default",
        value := Expr.lit (Literal.str "us-east-1")
      }
    ]
  }

#eval toSMTBlock awsRegionVariableBlock


def instanceTypeVariableBlock : Block :=
  { typ := BlockType.builtin "variable",
    labels := ["instance_type"],
    body := [
      BlockBodyItem.attr {
        name := "description",
        value := Expr.lit (Literal.str "The EC2 instance type.")
      },
      BlockBodyItem.attr {
        name := "type",
        value := Expr.var "string"
      },
      BlockBodyItem.attr {
        name := "default",
        value := Expr.lit (Literal.str "t2.micro")
      },
      BlockBodyItem.block {
        typ := BlockType.builtin "validation",
        labels := [],
        body := [
          BlockBodyItem.attr {
            name := "condition",
            value := Expr.func "contains" [
              Expr.listLit [
                Expr.lit (Literal.str "t2.micro"),
                Expr.lit (Literal.str "t3.small"),
                Expr.lit (Literal.str "m5.large")
              ],
              Expr.ref ["var", "instance_type"]
            ]
          },
          BlockBodyItem.attr {
            name := "error_message",
            value := Expr.lit (Literal.str "Invalid instance type. Must be one of t2.micro, t3.small, or m5.large.")
          }
        ]
      }
    ]
  }

#eval toSMTBlock instanceTypeVariableBlock


end HCL
