#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker run -p 8080:8080 -e PORT=8080 -e LEFT_VERSION=${left_version} -e RIGHT_VERSION=${right_version} -d ${container_image}:${podtato_version}