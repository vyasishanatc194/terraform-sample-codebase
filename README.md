# Project Stack

## Requirements

- awscli
- terraform
- docker
- serverless [if setting up automatic https certificate renewal with letsencrypt]
- Python environment with `boto3` installed

  

## Quick Intro
We use this repo to store terraform configuration used to deploy *dev* and *prod* environment.
Terraform needs to store its state somewhere: an s3 bucket and a table in dynodb.
We use a *master* AWS account for this.


## Folder and Files Structure:
- bin/:  
We store scripts that are not strictly related with terraform, but still useful for deployments. The main one is `create-secrets.py` which is used to create secret keys and store them in AWS ssm & the parameter store in AWS Systems Manager.

- environments/\<name\>/:  
Where "name" is the name of a terraform workspace (usually "dev" or "prod"). This contains a file called `variables.tfvars` defining params for the workspace.

- modules/\<name\>/:  
Where `name` is the name of the terraform module. This is our repository of private terraform packages. Each package is defined by a `main.tf` file containing the terraform logic, `variables.tf` defining input params of the module, `outputs.tf` defining the exposed variables of the module. For example, `modules/rds` contains the files which relate to AWS rds - the databases that are being used.

- task-definitions/:  
Each file in here is a definition of a fargate service, we reference this files from the main terraform script.

- tf-init/:  
Contains the terraform deployment script for `The Very First Time` deployment, see later.

- initialize.tf:  
All variables required, these variables can be overwritten by the `environments/<name>/` variables file.

- main.tf:  
The main terraform script.

- nacl.tf:  
List of network access control list polcies.

- parameters.tf:  
SSM parameters to define.

- policies.tf:  
List of AWS policies that we apply to IAM roles.

- secrets.tf:  
Reference to secrets in AWS.


## The Very First Time
The very first time means, that you are going to setup the AWS *master* account to store terraform state.

You need to setup terraform state resources:
- s3 bucket
- dynamodb table

Terraform use these resources to keep track of the state of multiple environments.
These resources needs to stored in a "master account" not in dev specific account.

**IMPORTANT:** Configure your AWS client with a profile called exiimaster.
Then run the initialization script:
```bash
cd tf-init
terraform init
terraform apply
```

## Deployment to AWS

First step is to set AWS secrets for each account.
Here the profile names:
- exiimaster: where terraform keep the states  
- exiidev: dev account  
- exiiprod: prod account  

```bash
aws configure
```

### Setup LetsEncrypt for Hosted Zone
If you setup a service on HTTPS you need an SSL certificate, Let's encrypt does that for you:
```bash
cd lambdas/letsencrpyt
# Create params.sh, use params.sh.example
source params.sh
serverless deploy
```

**IMPORTANT:** Currently letsencrypt is not working automatically. So create a certificate with certbot and upload in AWS manually.
Then update the environment/<name>/variables.tfvars with something like:
`ssl_certificate = "arn:aws:acm:eu-west-2:586734899630:certificate/4c0ce5e1-a768-4f34-8204-4beea3e54302"`

### Create Secrets
Make sure you are using the right aws profile (this must be per environmnet) - REQUIRES python3
Check the source of create-secrets.py to understand what secrets will be created.
Some secrets are randomly created, others are read from you environment.
```bash
# Create secrets
# Eg:
export AWS_REGION=eu-west-2
export AWS_PROFILE=xxxx
export EMAIL_HOST_PASSWORD=xxxx

python bin/create-secrets.py

# Or Rotate secrets (requires deployment to be able to use new secrets)
python bin/create-secrets.py --rotate=yes
```


### Deployment stack
If you are going to expose a service on HTTPS, you must create and deploy an SSL certificate (see also the letsencrypt bit).

If is the very first time an environment is deployed you need to register a new workspace in terraform.
Workspace is the way terraform keep tracks of different deployments.
```bash
terraform workspace new <ENV_NAME>
```

Now we are ready to deploy the environemnt:
```bash
. switch_environment.sh <ENV_NAME>
tf apply
```

### Task definitions

The task-definitions folder contains the configuration to the fargate services. The files are the following:
- concept.json: This contains the configuration for the frontend fargate service
- django.json: This conains the configuration for the backend fargate service

The other files in this folder are old and are no longer used.

### Making Changes to ECS Task definitions

When deploying changes to ECS task definitions, it is important the remember the role being played by the front end and back end repos as well. The terraform stack can make changes to the task definitions e.g. adding a new environment variable or making the task. However, the front and back end repos will deploy new docker images to ECS and update the Task to point to the new image. Terraform isn't aware of these process and so when making changes to any of the ECS tasks, it is possible that the Fargate task `will not point to the latest service`.

It is easy to manually update the service being used by the fargate task. Inside of the ECS cluster, click on the task that needs to be updated. Click on the update button in the top right and update it to the latest service.

### What after

Once the base stack is deployed, is time to work on the backend and frontend services.
You need to build and push the docker for both these services (currently done in circleci). Then as one-off run the fargate task migration (which uses the backend docker) to build the postgres db structure.


### Useful Links:

Documentations for aws vpc module: `https://github.com/terraform-aws-modules/terraform-aws-vpc`.
