# -----------------------------------------------------------------------------
# Security Groups Module - Outputs
# -----------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group (null if Redis is disabled)"
  value       = var.enable_redis ? aws_security_group.redis[0].id : null
}

output "btb_ec2_security_group_id" {
  description = "ID of the btb EC2 security group (null if btb EC2 is disabled)"
  value       = var.enable_btb_ec2 ? aws_security_group.btb_ec2[0].id : null
}
