# Let's Encrypt

## Update/Create Certificate

1. Generate new certificates manually
```bash
certbot certonly --manual --preferred-challenges dns
# Follow instructions
```

2. Update the online certificate

Let's encrypt save the information under /etc/letsencrypt/live

