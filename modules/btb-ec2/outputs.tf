# -----------------------------------------------------------------------------
# BTB EC2 Module - Outputs
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "ID of the btb-service EC2 instance"
  value       = aws_instance.btb.id
}

output "public_ip" {
  description = "Public IP address of the btb-service EC2 instance"
  value       = aws_instance.btb.public_ip
}

output "public_dns" {
  description = "Public DNS name of the btb-service EC2 instance"
  value       = aws_instance.btb.public_dns
}
