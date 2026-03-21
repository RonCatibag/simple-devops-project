output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins_mfe.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.jenkins_mfe.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.jenkins_mfe.public_dns
}

output "ssm_command" {
  description = "SSM Session Manager command to connect to the instance"
  value       = "aws ssm start-session --target ${aws_instance.jenkins_mfe.id}"
}

output "ami_id" {
  description = "AMI used for the instance"
  value       = data.aws_ami.amazon_linux.id
}

output "ssh_public_key_secret_arn" {
  description = "Secrets Manager ARN for the SSH public key"
  value       = aws_secretsmanager_secret.ssh_public_key.arn
}

output "ssh_private_key_secret_arn" {
  description = "Secrets Manager ARN for the SSH private key"
  value       = aws_secretsmanager_secret.ssh_private_key.arn
}

output "retrieve_private_key_command" {
  description = "AWS CLI command to retrieve the private key PEM from Secrets Manager"
  value       = "aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id ${aws_secretsmanager_secret.ssh_private_key.id} --query SecretString --output text"
}

output "billing_alarm_200_arn" {
  description = "CloudWatch billing alarm ARN ($200 threshold)"
  value       = aws_cloudwatch_metric_alarm.billing_200.arn
}

output "billing_sns_topic_arn" {
  description = "SNS topic ARN for billing alerts"
  value       = aws_sns_topic.billing_alert.arn
}
