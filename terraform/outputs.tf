output "alb_dns_name" {
  description = "Public DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
