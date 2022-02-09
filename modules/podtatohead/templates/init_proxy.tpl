#!/bin/bash
# vars available: ${elb_dns}
sudo yum update -y

sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo amazon-linux-extras install epel -y
sudo yum-config-manager --enable epel
sudo yum install certbot -y

sudo bash
#Get Public IP + DNS
export PUBLIC_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export PUBLIC_INSTANCE_NAME="$(curl http://169.254.169.254/latest/meta-data/public-hostname)"

certbot certonly --standalone --preferred-challenges http -d $PUBLIC_IPV4_ADDRESS.nip.io --register-unsafely-without-email --non-interactive --agree-tos

mkdir -p /app
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

