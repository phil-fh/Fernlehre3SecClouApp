resource "aws_instance" "proxy" {
  ami = data.aws_ami.amazon-2.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/init_proxy.tpl",{elb_dns = aws_elb.main_elb.dns_name})
  vpc_security_group_ids = [aws_security_group.ingress-all-http_8080.id, aws_security_group.ingress-all-ssh.id]
  tags = {
    Name = "podtatohead-proxy"
  }
  lifecycle {
    create_before_destroy = true
  }
}