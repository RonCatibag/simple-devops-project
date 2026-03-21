terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ec2.public_key_openssh
}

resource "aws_secretsmanager_secret" "ssh_public_key" {
  name        = "${var.project_name}/ssh-public-key"
  description = "EC2 SSH public key (auto-generated)"
  tags        = { Project = var.project_name }
}

resource "aws_secretsmanager_secret_version" "ssh_public_key" {
  secret_id     = aws_secretsmanager_secret.ssh_public_key.id
  secret_string = tls_private_key.ec2.public_key_openssh
}

resource "aws_secretsmanager_secret" "ssh_private_key" {
  name        = "${var.project_name}/ssh-private-key"
  description = "EC2 SSH private key PEM (auto-generated)"
  tags        = { Project = var.project_name }
}

resource "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id     = aws_secretsmanager_secret.ssh_private_key.id
  secret_string = tls_private_key.ec2.private_key_pem
}

resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.project_name}-secrets-read"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        aws_secretsmanager_secret.ssh_public_key.arn,
        aws_secretsmanager_secret.ssh_private_key.arn
      ]
    }]
  })
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Jenkins MFE stack"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

resource "aws_sns_topic" "billing_alert" {
  provider = aws.us_east_1
  name     = "${var.project_name}-billing-alert"
  tags     = { Project = var.project_name }
}

resource "aws_sns_topic_subscription" "billing_email" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.billing_alert.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "billing_200" {
  provider            = aws.us_east_1
  alarm_name          = "${var.project_name}-billing-200usd"
  alarm_description   = "Billing alarm: estimated charges exceed $200"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 200
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.billing_alert.arn]
  ok_actions    = [aws_sns_topic.billing_alert.arn]

  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_metric_alarm" "billing_50" {
  provider            = aws.us_east_1
  alarm_name          = "${var.project_name}-billing-50usd"
  alarm_description   = "Billing warning: estimated charges exceed $50 (approaching free tier limits)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 21600
  statistic           = "Maximum"
  threshold           = 50
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.billing_alert.arn]

  tags = { Project = var.project_name }
}

resource "aws_instance" "jenkins_mfe" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/userdata.sh", {
    cloudflare_tunnel_token    = var.cloudflare_tunnel_token
    git_repo_url               = var.git_repo_url
    project_name               = var.project_name
    aws_region                 = var.aws_region
    ssh_public_key_secret_id   = aws_secretsmanager_secret.ssh_public_key.id
    ssh_private_key_secret_id  = aws_secretsmanager_secret.ssh_private_key.id
  })

  tags = {
    Name    = "${var.project_name}-ec2"
    Project = var.project_name
  }
}
