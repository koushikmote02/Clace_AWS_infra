# -----------------------------------------------------------------------------
# ElastiCache Module - Outputs
# -----------------------------------------------------------------------------

output "endpoint" {
  description = "ElastiCache cluster endpoint address"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "port" {
  description = "ElastiCache cluster port"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "cluster_id" {
  description = "ElastiCache cluster ID"
  value       = aws_elasticache_cluster.main.cluster_id
}

output "arn" {
  description = "ARN of the ElastiCache cluster"
  value       = aws_elasticache_cluster.main.arn
}

# Constructed REDIS_URL for application use
output "redis_url" {
  description = "Constructed REDIS_URL for application"
  value       = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:${aws_elasticache_cluster.main.cache_nodes[0].port}"
}
