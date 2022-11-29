# print the public IP of the instance
output "app_public_ip" {
  description = "Public IP address of the app instance"
  value       = aws_eip.app.public_ip
}

output "app_private_ip" {
  description = "Private IP address of the app instance"
  value       = aws_eip.app.private_ip
}

output "database_private_ip" {
  description = "Private IP address of the database instance"
  value       = aws_instance.database.private_ip
}

output "redis_private_ip" {
  description = "Private IP address of the redis instance"
  value       = aws_instance.redis.private_ip
}

output "nat_private_ip" {
  description = "Private IP address of the nat instance"
  value       = aws_instance.nat.private_ip
}

# print the availability zone of the instance
output "availability_zones" {
  description = "Availability zones of Subnet and EC2 instance"
  value       = data.aws_availability_zones.available.names[0]
}
