output "app_url" {
  description = "URL do frontend via proxy"
  value       = "http://localhost:${var.proxy_port}"
}

output "api_url" {
  description = "URL do backend via proxy"
  value       = "http://localhost:${var.proxy_port}/api"
}

output "cadvisor_url" {
  description = "URL do cAdvisor (monitoramento)"
  value       = "http://localhost:${var.cadvisor_port}"
}
