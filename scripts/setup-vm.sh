#!/usr/bin/env bash
set -euo pipefail

echo "=== VM Bootstrap: Docker + Docker Compose ==="

if command -v docker &>/dev/null; then
    echo "Docker already installed: $(docker --version)"
else
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    sudo usermod -aG docker "$USER"
    echo "Docker installed. You may need to log out/in for group changes."
fi

if docker compose version &>/dev/null; then
    echo "Docker Compose plugin: $(docker compose version)"
else
    echo "ERROR: docker compose plugin not found." >&2
    exit 1
fi

echo ""
echo "=== Generating TLS certificates ==="
bash "$(dirname "$0")/generate-certs.sh"

echo ""
echo "=== Building and starting services ==="
cd "$(dirname "$0")/.."
docker compose up -d --build jenkins nginx

echo ""
echo "=== Setup complete ==="
echo "Jenkins:  http://localhost:8080  (direct)"
echo "HTTPS:    https://localhost      (via Nginx)"
echo ""
echo "Retrieve the initial Jenkins admin password:"
echo "  docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
