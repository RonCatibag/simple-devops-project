variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
  default     = "simple-jenkins-job"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro for free tier)"
  type        = string
  default     = "t2.micro"
}

variable "alert_email" {
  description = "Email address for billing alarm notifications"
  type        = string
}

variable "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token for the cloudflared container"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL to clone on the EC2 instance"
  type        = string
  default     = "https://github.com/ronaldcatibag/simple-jenkins-job.git"
}
