variable "region" {
  default     = "eu-west-2"
  description = "The region the resources will be created in."
}

variable "stage" {
  default = "dev"
}

variable "profile" {
  type = string
  description = "AWS profile to use"
}

variable "name" {
  type = string
  description = "Stack name used to tag the resources"
  default = "Exii"
}


variable "ssl_certificate" {
  type = string
  description = "The ARN to the ssl certificate used by the load balancer"
}

variable "route53_hosted_zone_name" {
  type = string
  description = "Domain name"
}

variable "frontend_prefix" {
  type = string
  description = "Frontend Domain name prefix"
}

variable "backend_prefix" {
  type = string
  description = "Frontend Domain name prefix"
}

variable "database_username" {
  type = string
  description = "The admin user for the RDS instance"
}

variable "database_name" {
  type = string
  description = "The database name for the RDS instance"
}

variable "frontend_base_url" {
  type = string
  description = "The base URL of the front end"
}

variable "stripe_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Stripe data downloads during onbaording"
}

variable "xero_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Xero data downloads during onbaording"
}

variable "google_analytics_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Google Analytics data downloads during onbaording"
}

variable "google_ads_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Google Ads data downloads during onbaording"
}

variable "facebook_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Facebook data downloads during onbaording"
}

variable "shopify_sqs_onboard_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger Shopify data downloads during onbaording"
}

variable "xero_verify_callback_url" {
  type = string
  description = "The url extension we use for the Xero oauth callback"
}

variable "api_url" {
  type = string
  description = "base url for the backend"
}

variable "engine_sqs_name" {
  type = string
  description = "The name of the SQS queue which is used to trigger the engine run"
}


# Borrowed from VPC Module from Terraform Module Repository:
variable "vpc_cidr" {
  type = string
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  default     = []
}

variable "vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  default     = []
}

variable "vpc_database_subnets" {
  type        = list
  description = "A list of database subnets"
  default     = []
}

variable "vpc_azs" {
  description = "A list of availability zones in the region"
  default     = []
}

variable "vpc_enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = false
}

variable "vpc_single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = false
}

variable "vpc_one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  default     = false
}


# variable "dynamodb-terraform-locks" {}
# variable "s3-terraform-state" {}

# variable "TemplateBucket" {
#   default = "exii-deployment-template"
# }
# variable "NamePrefix" {
#   type = "string"
#   default = "Exii"
# }
# variable "ArtifactStorageBucket" {
#   default = "exii-deployment-artifacts"
# }
# variable "PipeLineServiceBucket" {
#   default = "exii-deployment-service-template"
# }
# variable "BackendDomainPrefix" {
#   type = "string"
#   default = "office"
# }
# variable "VPCCIDR" {
#   type = "string"
# }
# variable "AvailabilityZones" {
#   type = "list"
#   default = ["a"]
# }

# variable "BackendPublicSubnetsCIDR" {
#   default = ["172.1.1.0/26", "172.1.1.64/26"]
# }
# variable "BackendPrivateSubnetsCIDR" {
#   default = ["172.1.1.128/26", "172.1.1.192/26"]
# }
# variable "FrontendVPCCIDR" {
#   default = "172.2.1.0/24"
# }
# variable "FrontendPublicSubnetsCIDR" {
#   default = ["172.2.1.0/26", "172.2.1.64/26"]
# }
# variable "FrontendPrivateSubnetsCIDR" {
#   default = ["172.2.1.128/26", "172.2.1.192/26"]
# }