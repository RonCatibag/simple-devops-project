#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="$(cd "$(dirname "$0")/../nginx/certs" && pwd)"
mkdir -p "$CERT_DIR"

if [ -f "$CERT_DIR/server.crt" ] && [ -f "$CERT_DIR/server.key" ]; then
    echo "Certificates already exist in $CERT_DIR — skipping."
    exit 0
fi

echo "Generating self-signed TLS certificate..."

openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$CERT_DIR/server.key" \
    -out    "$CERT_DIR/server.crt" \
    -subj   "/C=US/ST=State/L=City/O=DevOps/CN=localhost"

chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

echo "Certificates created:"
echo "  $CERT_DIR/server.crt"
echo "  $CERT_DIR/server.key"
