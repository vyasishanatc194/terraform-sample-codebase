provider "aws" {
  region = var.region
  profile = var.profile
}

terraform {
  required_providers {
    aws = {
      version = "3.64.1"
    }
    random = {
      version="3.1.0"
    }
  }
}


data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


resource "aws_route53_zone" "zone" {
  name = var.route53_hosted_zone_name
}

# Create 3-tiers VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name}-${var.stage}-vpc"
  azs = "${var.vpc_azs}"
  cidr = "${var.vpc_cidr}"

  public_subnets = "${var.vpc_public_subnets}"
  private_subnets = "${var.vpc_private_subnets}"
  database_subnets = "${var.vpc_database_subnets}"

  enable_nat_gateway = "${var.vpc_enable_nat_gateway}"
  single_nat_gateway = "${var.vpc_single_nat_gateway}"
  one_nat_gateway_per_az = "${var.vpc_one_nat_gateway_per_az}"

  public_dedicated_network_acl = true
  public_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["public_inbound"],
  )
  public_outbound_acl_rules = concat(
    local.network_acls["default_outbound"],
    local.network_acls["public_outbound"],
  )

  private_dedicated_network_acl = true
  private_inbound_acl_rules = concat(
    local.network_acls["private_inbound"],
    local.network_acls["default_inbound"]
  )
  private_outbound_acl_rules = concat(
    local.network_acls["private_outbound"],
    local.network_acls["default_outbound"]
  )

  database_dedicated_network_acl = true
  database_inbound_acl_rules = local.network_acls["database_inbound"]
  database_outbound_acl_rules = local.network_acls["default_outbound"]

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}


# Create alb for the frontend
module "alb-frontend" {
  source = "./modules/alb"
  name = "${var.name}-${var.stage}-frontend"
  public_subnets = "${module.vpc.public_subnets}"
  vpc_id = "${module.vpc.vpc_id}"
  ssl_certificate = "${var.ssl_certificate}"
  route53_hosted_zone_name = "${var.route53_hosted_zone_name}"
  host_destination = "${var.frontend_prefix}"
  zone_id = "${aws_route53_zone.zone.zone_id}"
}

# Create alb for the frontend demo
#module "alb-demo" {
#  source = "./modules/alb"
#  name = "demo"
#  public_subnets = "${module.vpc.public_subnets}"
#  vpc_id = "${module.vpc.vpc_id}"
#  ssl_certificate = "${var.ssl_certificate}"
#  route53_hosted_zone_name = "${var.route53_hosted_zone_name}"
#  host_destination = "${var.demo_prefix}"
#  zone_id = "${aws_route53_zone.zone.zone_id}"
#}

# Create alb for the django backend
module "alb-django" {
  source = "./modules/alb"
  name = "${var.name}-${var.stage}-django"
  public_subnets = "${module.vpc.public_subnets}"
  vpc_id = "${module.vpc.vpc_id}"
  ssl_certificate = "${var.ssl_certificate}"
  route53_hosted_zone_name = "${var.route53_hosted_zone_name}"
  host_destination = "${var.backend_prefix}"
  zone_id = "${aws_route53_zone.zone.zone_id}"
}


# Create ECS for the services (frontend and django)
module "ecs-service" {
  source = "./modules/ecs"
  name = "${var.name}-${var.stage}"
  policies = local.policies["frontend"]
  container_insights_enabled="disabled"
  repo = ["exii/concept", "exii/django"]
}

module "demo-ecs-service" {
  source = "./modules/ecs"
  name = "demo"
  policies = local.policies["frontend"]
  repo = ["exii/demo"]
  container_insights_enabled="disabled"
}


module "service-concept" {
  source = "./modules/pubservice"
  desiderable_count     = 1
  name                  = "exii-concept-${var.stage}"
  cluster_id            = "${module.ecs-service.cluster_id}"
  execution_role        = "${module.ecs-service.execution_role_arn}"
  task_role             = "${module.ecs-service.task_role_arn}"
  vpc                   = "${module.vpc}"
  target_arn            = "${module.alb-frontend.alb_target_group}"
  container_name        = "exii-concept"
  container_definitions = "${templatefile("./task-definitions/concept.json", {
          repository_url               = "${module.ecs-service.repository_urls.0}"
          logs_group                   = "${module.ecs-service.cloudwatch_name}",
          region_name                  = "${data.aws_region.current.name}",
          account_id                   = "${data.aws_caller_identity.current.account_id}",
          database_host                = "${module.rds.address}",
          database_port                = "5432",
          database_user                = "${var.database_username}",
          database_name                = "${var.database_name}",
          backend_site_url             = "https://${var.backend_prefix}.${var.route53_hosted_zone_name}",
          xero_verify_callback_url     = "${var.xero_verify_callback_url}",
    })
  }"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}

#We use the same task definition container name as exii-concept
#module "service-demo" {
#  source = "./modules/pubservice"
#  desiderable_count     = 1
#  name                  = "exii-demo"
#  cluster_id            = "${module.demo-ecs-service.cluster_id}"
#  execution_role        = "${module.demo-ecs-service.execution_role_arn}"
#  task_role             = "${module.demo-ecs-service.task_role_arn}"
#  vpc                   = "${module.vpc}"
#  target_arn            = "${module.alb-demo.alb_target_group}"
#  container_name        = "demo"
#  container_definitions = "${templatefile("./task-definitions/demo.json", {
#          repository_url               = "${module.demo-ecs-service.repository_urls.0}"
#          logs_group                   = "${module.demo-ecs-service.cloudwatch_name}",
#          region_name                  = "${data.aws_region.current.name}",
#          account_id                   = "${data.aws_caller_identity.current.account_id}",
#          database_host                = "${module.rds.address}",
#          database_port                = "5432",
#          database_user                = "${var.database_username}",
#          database_name                = "${var.database_name}",
#          backend_site_url             = "https://${var.backend_prefix}.${var.route53_hosted_zone_name}",
#          xero_verify_callback_url     = "${var.xero_verify_callback_url}",
#    })
#  }"
#  tags = {
#    Group       = "${var.name}"
#    Environment = "${var.stage}"
#  }
#}

module "service-django" {
  source = "./modules/pubservice"
  desiderable_count     = 1
  name                  = "exii-django-${var.stage}"
  cluster_id            = "${module.ecs-service.cluster_id}"
  execution_role        = "${module.ecs-service.execution_role_arn}"
  task_role             = "${module.ecs-service.task_role_arn}"
  vpc                   = "${module.vpc}"
  target_arn            = "${module.alb-django.alb_target_group}"
  container_name        = "exii-django"
  container_definitions = "${templatefile("./task-definitions/django.json", {
            repository_url               = "${module.ecs-service.repository_urls.1}",
            logs_group                   = "${module.ecs-service.cloudwatch_name}",
            django_allowed_cidr_nets     = "${join(",",concat(
                                                            module.vpc.public_subnets_cidr_blocks,
                                                            module.vpc.private_subnets_cidr_blocks
                                                            ))
                                            }",
            django_commit_hash                  = "",
            django_database_host                = "${module.rds.address}",
            django_database_name                = "${var.database_name}",
            django_database_port                = "5432",
            django_database_user                = "${var.database_username}",
            django_aws_storage_bucket_name      = "${aws_ssm_parameter.staging-bucket.value}",
            exii_base_domain                    = "${var.route53_hosted_zone_name}",
            django_backend_domain_prefix        = "${var.backend_prefix}",
            django_frontend_domain_prefix       = "${var.frontend_prefix}",
            frontend_base_url                   = "${var.frontend_base_url}",
            stripe_sqs_onboard_name             = "${var.stripe_sqs_onboard_name}",
            xero_sqs_onboard_name               = "${var.xero_sqs_onboard_name}",
            google_analytics_sqs_onboard_name   = "${var.google_analytics_sqs_onboard_name}",
            google_ads_sqs_onboard_name         = "${var.google_ads_sqs_onboard_name}",
            facebook_sqs_onboard_name           = "${var.facebook_sqs_onboard_name}",
            shopify_sqs_onboard_name            = "${var.shopify_sqs_onboard_name}",
            engine_sqs_name                     = "${var.engine_sqs_name}",
            xero_verify_callback_url            = "${var.xero_verify_callback_url}",
            region_name                         = "${data.aws_region.current.name}",
            account_id                          = "${data.aws_caller_identity.current.account_id}"
    })
  }"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}


# Create ECS for backend tasks (modelbuild)
module "ecs-bakend" {
  source = "./modules/ecs"
  name = "${var.name}-bakend-${var.stage}"
  container_insights_enabled = "enabled"
  policies = local.policies["default"]
  repo = [
    "exii/exii-base", 
    "exii/insight", 
    "exii/stripe", 
    "exii/xero", 
    "exii/googleanalytics", 
    "exii/googleads", 
    "exii/facebookads",
    "exii/shopify",
    "exii/engine"
    ]
}

# Register S3 Buckets
module "s3-log" {
  source = "./modules/s3"
  bucket  = "${aws_ssm_parameter.log-bucket.value}"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}

module "s3-staging" {
  source = "./modules/s3"
  bucket  = "${aws_ssm_parameter.staging-bucket.value}"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}

module "s3-trigger" {
  source = "./modules/s3"
  bucket  = "${aws_ssm_parameter.trigger-bucket.value}"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}

# We create a user input data bucket
module "s3-input" {
  source = "./modules/s3"
  bucket  = "${aws_ssm_parameter.input-bucket.value}"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}

# We create a bucket for storage of models
module "s3-model" {
  source = "./modules/s3"
  bucket  = "${aws_ssm_parameter.model-bucket.value}"
  tags = {
    Group       = "${var.name}"
    Environment = "${var.stage}"
  }
}


# Register RDS
module "rds" {
  source = "./modules/rds"
  vpc_id = "${module.vpc.vpc_id}"
  name = "${var.name}-${var.stage}"
  database_subnet_group = "${module.vpc.database_subnet_group}"
  database_name = "${var.database_name}"
  database_username = "${var.database_username}"
  database_password = "${data.aws_secretsmanager_secret.database_password.id}"
}



terraform {
  backend "s3" {
    bucket         = "exii-terraform-state"
    key            = "default/terraform.tfstate"
    region         = "eu-west-2"   # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-locks"
    profile        = "exiimaster"
    encrypt        = true
  }
}
