#!/bin/sh
DOMAIN="${DUCKDNS_DOMAIN:-localhost}"
LE_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
CERT_DIR="/etc/nginx/certs/live"

mkdir -p "$CERT_DIR"

if [ -f "$LE_CERT" ]; then
  echo "Using Let's Encrypt certificate for ${DOMAIN}"
  ln -sf "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "$CERT_DIR/fullchain.pem"
  ln -sf "/etc/letsencrypt/live/${DOMAIN}/privkey.pem"   "$CERT_DIR/privkey.pem"
else
  echo "Let's Encrypt cert not found — using self-signed fallback"
  ln -sf /etc/nginx/certs/server.crt "$CERT_DIR/fullchain.pem"
  ln -sf /etc/nginx/certs/server.key "$CERT_DIR/privkey.pem"
fi

exec nginx -g "daemon off;"
