#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user

sudo DD_HOSTNAME=${name} DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${dd_api_key} DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

sudo docker run -p 8080:8080 -e PORT=8080 -e HATS_HOST=${hats_host} -e HATS_PORT=8080 -e ARMS_HOST=${arms_host} -e ARMS_PORT=8080 -e LEGS_HOST=${legs_host} -e LEGS_PORT=8080 -d ${container_image}:${podtato_version}
