terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ttt_security_group" {
    name_prefix = "ttt_security_group"
    vpc_id = data.aws_vpc.default.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_key_pair" "ttt_kp" {
    key_name = "pc"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4QJZJ+AkijoThPe+disNSVrtuuS7d2W9sq7ih0fU6RM/rkFuavhG4DdXrsGIIQJUKFY5uNSGqTcdum9Ns9EhedXrKq0W8UJkgpjAkGfQBYwj575qsvh/83wWk9SeKEVRFhHxHhotpmNvpPN2F0eB8R0gidKJf46eNQ3BH9/ULHAj9ZH/hoXODWRAh5GPJ/Y14qpiJqP2bVqPgebU5XbZ6s2DiuVqrwSZ5sX1uRyJcKsJs9IcEAsrc4PGUKkLQ7MRZ+cdrM3hwju0Gj/7ulLIBDWhpWk6jvssadtj14eft3NEEbJeX6ss9Ej/8uYMHqHxMe0fcvVe5vuvXAOg0avh5OKDaoRHKxA5I/IEryVo3385jEFPtV0RhYSnJWdiBYUufG3LZnSAV4eAdclB7See25rK5S16BvkiX7nGMCN8h3ZkXW3C04D5FFq9p+PWi9LvCmZd+sS8VwcpL67xFGkId8srMl4hb0e52k3G4Vz4wouCNLpnTEI3z8rM5Xuj0vo0= lukasz@DESK-X570"
}

resource "aws_instance" "ttt_ec2" {
    ami = "ami-0e001c9271cf7f3b9"
    instance_type = "t2.micro"
    key_name = aws_key_pair.ttt_kp.key_name

    user_data = <<-EOF
        #!/bin/bash

        # Add Docker's official GPG key:
        sudo apt-get -y update
        sudo apt-get -y install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update

        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Run the app
        cd /var
        sudo mkdir app
        cd app
        sudo git clone https://github.com/swiszczoo/chmura1.git
        cd chmura1
        sudo docker compose -f docker-compose-prod.yml -d
    EOF

    vpc_security_group_ids = [
        aws_security_group.ttt_security_group.id,
    ]

    tags = {
        Name = "TicTacToe"
    }
}

output "public_ip" {
  value = aws_instance.ttt_ec2.public_ip
}
