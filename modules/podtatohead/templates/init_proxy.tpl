#!/bin/bash
# vars available: ${elb_dns}

sudo bash

sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo amazon-linux-extras install epel -y
sudo yum-config-manager --enable epel
sudo service docker start
sudo usermod -a -G docker ec2-user
#Get Public IP + DNS
export PUBLIC_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export PUBLIC_INSTANCE_NAME="$(curl http://169.254.169.254/latest/meta-data/public-hostname)"


mkdir -p /app
cat > /app/nginx.conf<< EOF
server { # simple reverse-proxy
    listen 80;
    #listen 443 ssl;
    server_name  ($PUBLIC_IPV4_ADDRESS).nip.io;

    location / {
      proxy_pass http://orf.at;
    }
}

EOF

docker run -d -p 80:80 -v /app/nginx.conf:/etc/nginx/conf.d/my.conf:ro --name nginx nginx
#-v /app/data/etc/live/$PUBLIC_IPV4_ADDRESS.sslip.io/fullchain.pem:/app/data/etc/live/$PUBLIC_IPV4_ADDRESS.sslip.io/fullchain.pem:rw
#-v /app/data/etc/live/$PUBLIC_IPV4_ADDRESS.sslip.io/privkey.pem:/app/data/etc/live/$PUBLIC_IPV4_ADDRESS.sslip.io/privkey.pem:rw

