#!/bin/bash
set -euxo pipefail

exec > /var/log/userdata.log 2>&1

# ── Swap (2 GB) — critical for t2.micro builds ──
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# ── System packages ──
dnf update -y
dnf install -y docker git jq

# ── Docker ──
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── Docker Compose (plugin) ──
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -L "https://github.com/docker/compose/releases/download/$${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ── CloudWatch Agent (basic monitoring) ──
dnf install -y amazon-cloudwatch-agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "metrics": {
    "namespace": "${project_name}",
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "swap": { "measurement": ["swap_used_percent"] },
      "disk": { "measurement": ["disk_used_percent"], "resources": ["*"] }
    },
    "append_dimensions": { "InstanceId": "$${aws:InstanceId}" }
  }
}
CWCONFIG
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ── SSH keys from Secrets Manager ──
SSH_DIR="/home/ec2-user/.ssh"
mkdir -p "$SSH_DIR"

aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${ssh_private_key_secret_id}" \
  --query 'SecretString' --output text \
  > "$SSH_DIR/id_rsa"

aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${ssh_public_key_secret_id}" \
  --query 'SecretString' --output text \
  > "$SSH_DIR/id_rsa.pub"

cat "$SSH_DIR/id_rsa.pub" >> "$SSH_DIR/authorized_keys"

chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/id_rsa" "$SSH_DIR/authorized_keys"
chmod 644 "$SSH_DIR/id_rsa.pub"
chown -R ec2-user:ec2-user "$SSH_DIR"

# ── Clone project ──
PROJECT_DIR="/home/ec2-user/${project_name}"
git clone "${git_repo_url}" "$PROJECT_DIR"
chown -R ec2-user:ec2-user "$PROJECT_DIR"

# ── Inject secrets ──
cat > "$PROJECT_DIR/.env" <<'ENVFILE'
CLOUDFLARE_TUNNEL_TOKEN=${cloudflare_tunnel_token}
ENVFILE
chown ec2-user:ec2-user "$PROJECT_DIR/.env"
chmod 600 "$PROJECT_DIR/.env"

# ── Start the stack ──
cd "$PROJECT_DIR"
docker compose up -d --build

echo ">>> userdata complete at $(date)" >> /var/log/userdata.log
