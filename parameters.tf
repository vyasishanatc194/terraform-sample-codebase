# This script will store parameters into ssm
# Static
resource "aws_ssm_parameter" "trigger-bucket"{
  name = "/exii/${var.stage}/trigger-bucket"
  type = "String"
  value = "exii-trigger-${var.stage}"
}

resource "aws_ssm_parameter" "input-bucket"{
  name = "/exii/${var.stage}/input-bucket"
  type = "String"
  value = "exii-input-${var.stage}"
}

resource "aws_ssm_parameter" "staging-bucket"{
  name = "/exii/${var.stage}/staging-bucket"
  type = "String"
  value = "exii-staging-${var.stage}"
}

resource "aws_ssm_parameter" "model-bucket"{
  name = "/exii/${var.stage}/model-bucket"
  type = "String"
  value = "exii-model-${var.stage}"
}

# resource "aws_ssm_parameter" "output-bucket"{
#   name = "/exii/${var.stage}/output-bucket"
#   type = "String"
#   value = "exii-output-${var.stage}"
# }

resource "aws_ssm_parameter" "log-bucket"{
  name = "/exii/${var.stage}/log-bucket"
  type = "String"
  value = "exii-log-${var.stage}"
}

resource "aws_ssm_parameter" "report-bucket"{
  name = "/exii/${var.stage}/report-bucket"
  type = "String"
  value = "exii-report-${var.stage}"
}

# Dynamic
resource "aws_ssm_parameter" "database-host"{
  name = "/exii/${var.stage}/database/host"
  type = "String"
  value = module.rds.address
}

# Environmnet dependant
resource "aws_ssm_parameter" "database-name"{
  name = "/exii/${var.stage}/database/name"
  type = "String"
  value = var.database_name
}

resource "aws_ssm_parameter" "database-username"{
  name = "/exii/${var.stage}/database/username"
  type = "String"
  value = var.database_username
}

# Cluster names for the backend e.g. the model build
resource "aws_ssm_parameter" "cluster_backend"{
name = "/exii/${var.stage}/backend/cluster"
type = "String"
value = module.ecs-bakend.cluster_name
}

resource "aws_ssm_parameter" "cluster_backend_subnets"{
name = "/exii/${var.stage}/backend/cluster-subnets"
type = "String"
value = join(",",concat(module.vpc.public_subnets_cidr_blocks))
}

resource "aws_ssm_parameter" "cluster_backend_subnet_ids"{
name = "/exii/${var.stage}/backend/cluster-subnet-ids"
type = "String"
value = join(",",concat(module.vpc.public_subnets))
}

# Store the api URL for access by the lambdas
resource "aws_ssm_parameter" "api_url"{
name = "/exii/${var.stage}/api-url"
type = "String"
value = var.api_url
}
