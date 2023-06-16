import boto3
import certbot.main
import datetime
import os
import subprocess


CERTBOT_SERVER = 'https://acme-v02.api.letsencrypt.org/directory'


def read_and_delete_file(path):
    with open(path, 'r') as file:
        contents = file.read()
    os.remove(path)
    return contents


def provision_cert(email, domains):
    certbot.main.main([
        # Obtain a cert but don't install it
        'certonly',
        # Run in non-interactive mode
        '--non-interactive',
        # Agree to the terms of service,
        '--agree-tos',
        # Email
        '--email', email,
        # Use dns challenge with route53
        '--dns-route53',
        '--preferred-challenges', 'dns-01',
        # Domains to provision certs
        '--domains', domains,
        # Use this server instead of default acme-v01
        '--server', CERTBOT_SERVER,
        # Override directory paths so script doesn't have to be run as root
        '--config-dir', '/tmp/config-dir/',
        '--work-dir', '/tmp/work-dir/',
        '--logs-dir', '/tmp/logs-dir/',
    ])

    first_domain = domains.split(',')[0]
    path = '/tmp/config-dir/live/' + first_domain + '/'
    return {
        'certificate': read_and_delete_file(path + 'cert.pem'),
        'private_key': read_and_delete_file(path + 'privkey.pem'),
        'certificate_chain': read_and_delete_file(path + 'chain.pem')
    }


def should_provision(domains):
    existing_cert = find_existing_cert(domains)
    if existing_cert:
        now = datetime.datetime.now(datetime.timezone.utc)
        not_after = existing_cert['Certificate']['NotAfter']
        return (not_after - now).days <= 30
    else:
        return True


def find_existing_cert(domains):
    domains = frozenset(domains.split(','))

    client = boto3.client('acm')
    paginator = client.get_paginator('list_certificates')
    iterator = paginator.paginate(PaginationConfig={'MaxItems': 1000})

    for page in iterator:
        for cert in page['CertificateSummaryList']:
            cert = client.describe_certificate(CertificateArn=cert['CertificateArn'])
            sans = frozenset(cert['Certificate']['SubjectAlternativeNames'])
            if sans.issubset(domains):
                return cert

    return None


def notify_via_sns(topic_name, domains, certificate):
    process = subprocess.Popen(['openssl', 'x509', '-noout', '-text'],
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE, encoding='utf8')
    stdout, stderr = process.communicate(certificate)

    client = boto3.client('sns')
    topic = client.create_topic(Name=topic_name)
    client.publish(
        TopicArn=topic['TopicArn'],
        Subject='Issued new LetsEncrypt certificate',
        Message='Issued new certificates for domains: ' + domains + '\n\n' + stdout,
    )


def upload_cert_to_acm(cert, domains):
    existing_cert = find_existing_cert(domains)
    certificate_arn = existing_cert['Certificate']['CertificateArn'] if existing_cert else None

    kwargs = dict(
        Certificate=cert['certificate'],
        PrivateKey=cert['private_key'],
        CertificateChain=cert['certificate_chain'],
    )

    client = boto3.client('acm')
    if certificate_arn:
        kwargs.update(
            CertificateArn=certificate_arn,
        )

    acm_response = client.import_certificate(**kwargs)

    return certificate_arn if certificate_arn else acm_response['CertificateArn']


def handler(event, context):
    try:
        domains = os.environ['LETSENCRYPT_DOMAINS']
        if should_provision(domains):
            cert = provision_cert(os.environ['LETSENCRYPT_EMAIL'], domains)
            upload_cert_to_acm(cert, domains)
            notify_via_sns(os.environ['NOTIFICATION_SNS_TOPIC'], domains, cert['certificate'])
    except:
        raise
