output "allow_web_id" {
  value = aws_security_group.allow_web.id
}

output "allow_ssh_id" {
  value = aws_security_group.allow_ssh.id
}

output "allow_cicd_traffic_id" {
  value = aws_security_group.allow_cicd_traffic.id
}

output "allow_mongodb_id" {
  value = aws_security_group.allow_mongodb.id
}

output "allow_monitoring_id" {
  value = aws_security_group.allow_monitoring.id
}
