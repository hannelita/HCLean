# HCLean

Requires:
- Lean 4
- Terraform

## Simple HCL example for AWS
(AI generated, jusr for context)

```
# main.tf

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Define an input variable for the AWS region
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

# Define an input variable for instance type, with validation
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.small", "m5.large"], var.instance_type)
    error_message = "Invalid instance type. Must be one of t2.micro, t3.small, or m5.large."
  }
}

# Look up an existing AMI (Data Source)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create an EC2 instance (Resource)
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id # Reference the AMI ID from the data source
  instance_type = var.instance_type      # Use the variable for instance type
  tags = {
    Name        = "${local.project_name}-web-server" # Using a local value
    Environment = "Development"
  }
  # Security group (simplified for example)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}

# Define a local value for consistent naming
locals {
  project_name = "my-terraform-project"
}

# Create a security group for the web server
resource "aws_security_group" "web_sg" {
  name        = "${local.project_name}-web-security-group"
  description = "Allow HTTP and SSH inbound traffic"
  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from everywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the public IP address of the EC2 instance
output "web_server_public_ip" {
  description = "The public IP address of the web server."
  value       = aws_instance.web_server.public_ip
}
```

## Basic BNF sketch

```
<HCLConfig> ::= ( <RootLevelItem> | <Comment> )*

<RootLevelItem> ::= <TopLevelBlock> | <TopLevelAttribute>

<TopLevelAttribute> ::= <Identifier> "=" <Expression>
    -- Attributes that can appear directly at the root, though less common outside of specific
    -- configurations like backend attributes within the 'terraform' block when defined explicitly.

<TopLevelBlock> ::= <TopLevelBlockType> ( <Label> )* "{" <BlockBody> "}"
<TopLevelBlockType> ::=
    "resource"
    | "data"
    | "variable"
    | "output"
    | "provider"
    | "terraform"
    | "locals"
    | "module"

<Block> ::= <AnyBlockType> ( <Label> )* "{" <BlockBody> "}"
<BlockBody> ::= ( <Attribute> | <Block> | <Comment> )*

<Attribute> ::= <Identifier> "=" <Expression>

<AnyBlockType> ::=
    <TopLevelBlockType>  -- A top-level block type can also be used as a nested block (e.g., within a module)
    | <Identifier>       -- For nested block types like 'ingress', 'connection', 'provisioner', 'setting', etc.

<Label> ::= <Identifier> | <StringLiteral>

<Expression> ::=
    <Literal>
    | <CollectionLiteral>
    | <Reference>
    | <FunctionCall>
    | <ConditionalExpression>
    | <ForExpression>
    | <TemplateString>
    | <AttributeAccess>
    | <IndexAccess>
    | "(" <Expression> ")"  -- Parenthesized expression for explicit precedence

<Literal> ::= <StringLiteral> | <NumberLiteral> | <BooleanLiteral> | <NullLiteral>

<CollectionLiteral> ::= <ListLiteral> | <ObjectLiteral>

<ListLiteral> ::= "[" ( <Expression> ( "," <Expression> )* )? "]"

<ObjectLiteral> ::= "{" ( <ObjectField> ( "," <ObjectField> )* )? "}"
<ObjectField> ::= <ObjectKey> "=" <Expression>
<ObjectKey> ::= <Identifier> | <StringLiteral> | <Expression> -- Computed keys are allowed

<Reference> ::=
    <Identifier>                                  -- Simple identifier reference (e.g., in 'locals' or within the same block)
    | "var" "." <Identifier>                      -- Variable reference (e.g., `var.region`)
    | "local" "." <Identifier>                    -- Local value reference (e.g., `local.prefix`)
    | "resource" "." <Identifier> "." <Identifier> "." <Identifier> -- Canonical resource attribute (e.g., `resource.aws_instance.web.id`)
    | "data" "." <Identifier> "." <Identifier> "." <Identifier>     -- Canonical data source attribute (e.g., `data.aws_ami.ubuntu.id`)
    | "module" "." <Identifier> "." <Identifier>                    -- Module output reference (e.g., `module.vpc.vpc_id`)
    | <TopLevelBlockType> "." <Identifier> ( "." <Identifier> )?    -- Common shorthand for resource/data/provider attributes (e.g., `aws_instance.web.id`, `provider.aws`)

<FunctionCall> ::= <Identifier> "(" ( <Expression> ( "," <Expression> )* )? ")"

<ConditionalExpression> ::= <Expression> "?" <Expression> ":" <Expression>

<ForExpression> ::= <ForListExpression> | <ForObjectExpression>

<ForListExpression> ::= "[" "for" <LoopVars> "in" <Expression> ":" <Expression> ( "if" <Expression> )? "]"
<ForObjectExpression> ::= "{" "for" <LoopVars> "in" <Expression> ":" <Expression> "=>" <Expression> ( "if" <Expression> )? "}"
<LoopVars> ::= <Identifier> | <Identifier> "," <Identifier> -- Single (value) or two (key, value) loop variables

<TemplateString> ::= '"' ( <TextContent> | <Interpolation> )* '"'
<TextContent> ::= (any character except '"', '$', or '\' that is not part of an escape sequence)*
<Interpolation> ::= "${" <Expression> "}"

<AttributeAccess> ::= <Expression> "." <Identifier>
<IndexAccess> ::= <Expression> "[" <Expression> "]"

-- Lexical Elements (Simplified for grammar context)
<Identifier> ::= [a-zA-Z_][a-zA-Z0-9_-]*
<StringLiteral> ::= '"' (any character except '"' or '\')* '"' -- Assumed to handle basic escapes, but for template strings, see <TemplateString>
<NumberLiteral> ::= [0-9]+(\.[0-9]+)?
<BooleanLiteral> ::= "true" | "false"
<NullLiteral> ::= "null"
<Comment> ::= "#.*" | "//.*" | "/* .* */"

```