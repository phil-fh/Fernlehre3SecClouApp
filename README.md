# Fern3SecClouApp
Fernlehre 3
Das Ziel dieser Übung ist die unter https://fhb-codelabs.github.io/codelabs/virt-pt-terraform-ec2-cloudinit/index.html bereitgestellte Microservice Applikation entsprechend der erworbenen Fähigkeiten abzusichern. Die groben Konzepte dafür wurden bereits in der LV vorgestellt

**Schlagworte**
- Verbesserung der Ausfallsicherheit
- Transportverschlüsselung
- ~~Secrets~~
- ~~Authentifizierung~~
- Supply Chain
- Observability

## Maßnahmen zur Absicherung des Microservice Applikation

### 1. Verbesserung der Ausfallsicherheit

Um die Ausfallsicherheit unserer Microservie Applikation zu erhöhen, wurde ein Load Balancer eingerichtet. Dadurch erfolgt bei hoher Auslastung eine Lastverteilung auf mehrere Server, der Microservice bleibt aber unter der selben Adresse erreichbar. Neben der erhöhten Ausfallsicherheit, können auch die Zugriffszeiten verkürzt werden.

Um zu prüfen ob der Load Balancer auch wirklich funktioniert, wurden während der Testphase bewusst Ausfälle provuziert, um zu prüfen ob die Services trotzdem weiterlaufen.

### 2. Transportverschlüsselung

Der nächste Schritt um die Ausfallsicherheit zu erhöhen, war ein SSL-Zertifikat über LetsEncrytp zu erstellen und für unsere Microservice Applikation zu hinterlegen. Dafür wurde eine NGINX-Proxy Instanz erstellt, die das SSL-Zertifikat verwendet, welche in einem Docker-Container läuft.

Der Finale Setup ist wie folgt:

<details><summary>Übersicht über alle Projekte im Respository:</summary>
<p>

 ```
#prox.tf
resource "aws_instance" "proxy" {
  ami = data.aws_ami.amazon-2.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/init_proxy.tpl",{elb_dns = aws_elb.main_elb.dns_name})
  vpc_security_group_ids = [aws_security_group.ingress-all-http_8080.id, aws_security_group.ingress-all-ssh.id,aws_security_group.ingress-all-https_443.id,aws_security_group.elb_http.id]
  tags = {
    Name = "${var.podtato_name}-proxy"
  }
  lifecycle {
    create_before_destroy = true
  }
}
 
 
#init_proxy.tpl
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

#install oauth-proxy
#yum install git -y

#Get Public IP + DNS
export PUBLIC_IPV4_ADDRESS="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"
export PUBLIC_INSTANCE_NAME="$(curl http://169.254.169.254/latest/meta-data/public-hostname)"

mkdir -p /app
certbot certonly --standalone --preferred-challenges http -d $PUBLIC_IPV4_ADDRESS.nip.io --register-unsafely-without-email --non-interactive --agree-tos >> /app/log_certbot 2>&1

#connect github
# create new oauth app and register links
# store new client ID and client secret from github into

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
```

 </p>
</details>

### 3. Supply Chain

Eine unkomplizierte und doch sehr sichere Möglichkeit seine Infrastrucure as Code und somit auch die Microservice Applikation auf Fehler und Schwachstellen zu prüfen ist die Nutzung des Tools ***Snyk***. Hierbei handelt es sich um eine Cloudlösung, bei der die Konfigurationsdatei überprüft wird. Das bedeutet, dass keine zusätzliche Installation von Software, weder lokal noch über Terraform in den Instanzen notwendig ist und feststellen zu können ob die Sicherheit gewährleistet ist oder nicht.

<details><summary>Übersicht über alle Projekte im Respository:</summary>
<p>

![image](https://user-images.githubusercontent.com/90909702/153610286-b9ba8e7b-3c93-471f-a626-ddb03fa72a13.png)

 </p>
</details>

<details><summary>Im Detail sieht es dann wie folgt aus:</summary>
<p>

![image](https://user-images.githubusercontent.com/90909702/153609903-1528faa3-7f11-4311-8689-a70fbc57a749.png)

 </p>
</details>

Es wurde bereits mit anderen Tools bezüglich der Überprüfung auf Schwachstellen gearbeitet unter anderem ```tfsec``` und ```checkov```, allerdings zeigen diese das Ergebnis in erster Linie in der Console an und ist somit unübrsichtlicher und aufwendiger zum Interpretieren.

### 4. Observability

Um die Instancen zu überwachen (monitoring) wurden 2. Observability-Tools näher ins Auge gefasst: ```Grafana``` und ```Datadog```. Zuerst haben wir uns näher mit ```Grafana``` beschäftigt.

```Grafana```: Ist eine Open Source Lösung und bietet an und für sich eine sehr gute Oberfläche und Möglichkeiten sein Dashboard zum Überwachen der Instanzen. Der Service lässt sich auch über ```Terraform``` installieren und im Internet finden sich auch Konfigurationen, welche man als Vorlage verwenden kann.

```Datadog```: Genauso wie Grafana handelt es sich hierbei um eine Open Source Lösung die im Free Trial bereits eine Vielzahl an Möglichkeiten bietet. Der Service lässt sich ebenso über ```Terraform``` installieren. Auch für Datadog findet man Unterstützung im Netzt vom Hersteller und von der Community.

Es ist dann die Entscheidung auf Datadog gefallen, weil, auch wenn sich ```Grafana``` wie auch ```Datadog``` über ```Terraform``` installieren lassen, hat es mit ```Datadog``` doch etwas besser funktioniert.

<details><summary>Datadog CPU Monitoring</summary>

Alle Instanzen liefern werte beim Monitoring

![image](https://user-images.githubusercontent.com/90909702/153657770-eea0b854-6b0f-4031-a8a9-6d110016867b.png)

 </p>
</details>

<details><summary>Datadog Dashboard</summary>

Das Dashboard für Kunde1-main

![image](https://user-images.githubusercontent.com/90909702/153657618-5a5b10cf-9afe-45c2-891d-a052f5c831cf.png)

 </p>
</details>
