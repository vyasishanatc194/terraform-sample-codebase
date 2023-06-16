region = "eu-west-2"
stage="prod"
profile="exiiprod"

# Stack Name
name = "exii-concept"

# Networking
vpc_cidr     = "10.0.0.0/16"
vpc_azs      = ["eu-west-2a", "eu-west-2b"]
vpc_public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
vpc_private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
vpc_database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

# DNS
route53_hosted_zone_name = "exii.co"
frontend_prefix = "app"
backend_prefix = "api"

frontend_base_url = "https://app.exii.co/"

# SSL
ssl_certificate = "arn:aws:acm:eu-west-2:459873677450:certificate/cc18bf77-2a1f-468c-97b0-1c647553f910"

# RDS
database_name = "app"
database_username = "postgres"

# SQS
stripe_sqs_onboard_name = "StripeDownloaderStarterQueue"
xero_sqs_onboard_name = "XeroDownloaderStarterQueue"
google_analytics_sqs_onboard_name = "GoogleAnalyticsDownloaderStarterQueue"
google_ads_sqs_onboard_name = "GoogleadsDownloaderStarterQueue"
facebook_sqs_onboard_name = "FacebookadsDownloaderStarterQueue"
shopify_sqs_onboard_name = "ShopifyDownloaderStarterQueue"
engine_sqs_name = "EngineStarterQueue"

# Xero
xero_verify_callback_url = "connect/xero/callback"

# api url
api_url = "https://api.exii.co"

