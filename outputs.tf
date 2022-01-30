output "podtato-url" {
  value = "http://${aws_instance.podtatohead-main.public_ip}:8080"
}