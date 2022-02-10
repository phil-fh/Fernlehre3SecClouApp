#!/bin/bash
# vars available: ${elb_dns}
sudo bash
yum update -y

#install docker
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

#install certbot
amazon-linux-extras install epel -y
yum-config-manager --enable epel
yum install certbot -y

#install git CLI
#yum install git -y

#Get Public IP + DNS
export PUBLIC_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export PUBLIC_INSTANCE_NAME="$(curl http://169.254.169.254/latest/meta-data/public-hostname)"

mkdir -p /app
certbot certonly --standalone --preferred-challenges http -d $PUBLIC_IPV4_ADDRESS.nip.io --register-unsafely-without-email --non-interactive --agree-tos >> /app/log_certbot 2>&1

cat > /app/nginx.conf<< EOF
server { # simple reverse-proxy
    listen 80;
    listen 443 ssl;
    server_name $PUBLIC_IPV4_ADDRESS;

    ssl_certificate /etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/privkey.pem;

    location / {
      proxy_pass http://${elb_dns}/;
    }
}

EOF

docker run -p 443:443 -v /app/nginx.conf:/etc/nginx/conf.d/my.conf:ro -v /etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/fullchain.pem:/etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/fullchain.pem:rw -v /etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/privkey.pem:/etc/letsencrypt/live/$PUBLIC_IPV4_ADDRESS.nip.io/privkey.pem:rw --name nginx nginx