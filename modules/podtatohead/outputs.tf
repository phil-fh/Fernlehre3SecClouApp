output "podtato-elb-url" {
  value = "http://${aws_elb.main_elb.dns_name}"
}
output "podtato-proxy-url" {
  value = "https://${aws_instance.proxy.public_ip}.nip.io"
}