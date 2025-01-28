provider "aws" {
  region = "us-east-1"
}

# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"
  name    = "devops-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# RDS
resource "aws_rds_cluster" "db" {
  cluster_identifier      = "devops-db-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "13.9"  # Updated version
  database_name           = "devops_db"
  master_username         = "dbadmin"
  master_password         = "password123"
  skip_final_snapshot     = true
  availability_zones      = module.vpc.azs
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
}


resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

# Lambda IAM Role Policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Lambda Archive File (Absolute path used here)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "C:/Users/HP/Desktop/alveum-terraform-assignment/src/lambda/index.js"  # Absolute path
  output_path = "${path.module}/lambda.zip"
}

# Lambda Function
resource "aws_lambda_function" "core_service" {
  function_name    = "core-service"
  runtime          = "nodejs16.x"
  handler          = "index.handler"
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.lambda_zip.output_path
  environment {
    variables = {
      RDS_HOST   = aws_rds_cluster.db.endpoint
      CACHE_HOST = aws_elasticache_cluster.cache.configuration_endpoint
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "lambda-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# ElasticCache
resource "aws_elasticache_cluster" "cache" {
  cluster_id           = "devops-cache"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"  # Updated for Redis 7
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet.name
}

resource "aws_elasticache_subnet_group" "cache_subnet" {
  name       = "cache-subnet-group"
  subnet_ids = module.vpc.private_subnets
}
