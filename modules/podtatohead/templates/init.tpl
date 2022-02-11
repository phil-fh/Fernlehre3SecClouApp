#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo DD_HOSTNAME=${name} DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${dd_api_key} DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"


sudo docker run -p 8080:8080 -e PORT=8080 -e LEFT_VERSION=${left_version} -e RIGHT_VERSION=${right_version} -d ${container_image}:${podtato_version}