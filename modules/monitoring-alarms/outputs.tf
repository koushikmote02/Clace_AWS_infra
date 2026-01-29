# -----------------------------------------------------------------------------
# Monitoring Alarms Module - Outputs
# -----------------------------------------------------------------------------

output "cpu_alarm_arn" {
  description = "ARN of the ECS CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "memory_alarm_arn" {
  description = "ARN of the ECS memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "alb_5xx_alarm_arn" {
  description = "ARN of the ALB 5xx error rate alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_high.arn
}
