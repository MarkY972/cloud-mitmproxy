output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "db_instance_address" {
  description = "The address of the database instance."
  value       = aws_db_instance.main.address
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.main.dns_name
}
