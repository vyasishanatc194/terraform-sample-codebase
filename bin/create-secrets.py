#!/usr/bin/env python
import enum
import os
import sys
import random
from string import Template

import boto3
from botocore.exceptions import ClientError


class KeyType(enum.Enum):
    EnvVariable = 'env-variable'
    Secure = 'secure'


REGION = os.getenv('AWS_REGION', 'eu-west-2')
AWS_SECRETMANGER_ENDPOINT_URL = os.getenv('AWS_SECRETMANGER_ENDPOINT_URL', None)


def generate_secret(length=50):
    allowed_chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    return ''.join(random.choice(allowed_chars) for __ in range(length))


# Format: KeyName, Type, Value, Rotatable
SECRETS = [
    # Xero secrets
    ('xero/consumer-key', KeyType.EnvVariable, 'XERO_CONSUMER_KEY', True),
    ('xero/consumer-secret', KeyType.EnvVariable, 'XERO_CONSUMER_SECRET', True),
    ('xero/partner-secret', KeyType.EnvVariable, 'XERO_PARTNER_SECRET', True),

    # Codat secret
    ('codat/api-key', KeyType.EnvVariable, 'CODAT_API_KEY', True),

    # Secret-key controls password hashing so it should not be overwritten for most cases
    ('django/secret-key', KeyType.Secure, 50, False),

    # Secret-key controls password hashing so it should not be overwritten for most cases
    ('flask/secret-key', KeyType.Secure, 50, False),

    ('backend/admin-shared-secret', KeyType.Secure, 50, False),
    ('backend/cron-shared-secret', KeyType.Secure, 50, False),
    ('backend/worker-shared-secret', KeyType.Secure, 50, False),
    ('backend/finalizer-shared-secret', KeyType.Secure, 50, False),

    ('backend/email-host-password', KeyType.EnvVariable, 'EMAIL_HOST_PASSWORD', True),

    ('database/password', KeyType.Secure, 50, False),
    ('backend/stripe_secret', KeyType.EnvVariable, 'STRIPE_SECRET', False),
    ('backend/stripe_client', KeyType.EnvVariable, 'STRIPE_CLIENT', False),
    ('backend/sendgrid_api_key', KeyType.EnvVariable, 'SENDGRID_API_KEY', False),
           
    ('backend/xero-worker-shared-secret', KeyType.EnvVariable, 'XERO_WORKER_SHARED_SECRET', False),
    
    # Xero oauth 2.0 secrets
    ('xero/client-id', KeyType.EnvVariable, 'XERO_CLIENT_ID', True),
    ('xero/client-secret', KeyType.EnvVariable, 'XERO_CLIENT_SECRET', True),
           
   # Google Analytics secrets
   ('google-analytics/client-id', KeyType.EnvVariable, 'GOOGLE_ANALYTICS_CLIENT_ID', True),
   ('google-analytics/client-secret', KeyType.EnvVariable, 'GOOGLE_ANALYTICS_CLIENT_SECRET', True),
           
    # Google Ads secrets
    ('google-ads/client-id', KeyType.EnvVariable, 'GOOGLE_ADS_CLIENT_ID', True),
    ('google-ads/client-secret', KeyType.EnvVariable, 'GOOGLE_ADS_CLIENT_SECRET', True),
    ('google-ads/developer-token', KeyType.EnvVariable, 'GOOGLE_ADS_DEVELOPER_TOKEN', True),
           
    # Facebook secrets
    ('facebook-ads/app-id', KeyType.EnvVariable, 'FACEBOOK_APP_ID', True),
    ('facebook-ads/app-secret', KeyType.EnvVariable, 'FACEBOOK_APP_SECRET', True),
           
    # Shopify secrets
    ('shopify/api-key', KeyType.EnvVariable, 'SHOPIFY_API_KEY', True),
    ('shopify/api-secret-key', KeyType.EnvVariable, 'SHOPIFY_API_SECRET_KEY', True),

    # Engine shared secret
    ('backend/engine-shared-secret', KeyType.Secure, 50, False)
]


def create_parameters_store(rotate_secrets: bool = False, prefix=None):
    session = boto3.session.Session()

    secret_manager_client = session.client(
        service_name='secretsmanager',
        region_name=REGION,
        endpoint_url=AWS_SECRETMANGER_ENDPOINT_URL,
    )

    for key_name, key_type, parameter, can_rotate in SECRETS:
        if prefix is not None and prefix not in key_name:
            continue

        secret_key_name = Template('/exii/${key_name}').substitute(
            key_name=key_name,
        )

        try:
            secret_manager_client.describe_secret(SecretId=secret_key_name)
            secret_exists = True
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceNotFoundException':
                secret_exists = False

            else:
                raise e

        save_secret = not secret_exists or (secret_exists and can_rotate and rotate_secrets)

        if save_secret:
            if key_type == KeyType.EnvVariable and parameter in os.environ:
                value = os.environ[parameter]

            elif key_type == KeyType.Secure:
                value = generate_secret(parameter)

            else:
                continue

            print(f'Saving secret: {secret_key_name}')
            if secret_exists:
                secret_manager_client.put_secret_value(
                    SecretId=secret_key_name,
                    SecretString=value,
                )

            else:
                secret_manager_client.create_secret(
                    Name=secret_key_name,
                    SecretString=value,
                )


if __name__ == '__main__':
    args = sys.argv
    rotate = False
    prefix = None
    for arg in args[1:]:
        if arg == '--rotate=yes':
            rotate = True

        elif prefix is None:
            prefix = arg

    create_parameters_store(rotate_secrets=rotate, prefix=prefix)
