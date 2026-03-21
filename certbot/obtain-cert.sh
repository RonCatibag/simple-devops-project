#!/bin/sh
set -e

CERT_DIR="/etc/letsencrypt/live/${DUCKDNS_DOMAIN}"

if [ -f "$CERT_DIR/fullchain.pem" ]; then
  echo "Certificate exists — attempting renewal..."
  certbot renew --non-interactive
else
  echo "No certificate found — requesting new one..."
  certbot certonly \
    --authenticator dns-duckdns \
    --dns-duckdns-token "${DUCKDNS_TOKEN}" \
    --dns-duckdns-propagation-seconds 60 \
    --domain "${DUCKDNS_DOMAIN}" \
    --email "${LETSENCRYPT_EMAIL}" \
    --agree-tos \
    --non-interactive \
    --keep-until-expiring
fi

echo "Done. Certificate files:"
ls -la "$CERT_DIR/" 2>/dev/null || echo "(not yet available)"
