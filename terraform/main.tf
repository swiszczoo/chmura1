terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

# Region, w którym znajduje się lab AWS Academy
provider "aws" {
    region = "us-east-1"
}

# Sieć VPC
resource "aws_vpc" "ttt_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "TicTacToe VPC"
    }
}

# Jedyna podsieć w sieci VPC o adresie 10.0.1.0/24
resource "aws_subnet" "ttt_subnet_pub" {
    vpc_id = aws_vpc.ttt_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "TicTacToe VPC Public Subnet"
    }
}

# Brama, która wpuszcza ruch z internetu do VPC
resource "aws_internet_gateway" "ttt_gateway" {
    vpc_id = aws_vpc.ttt_vpc.id
    tags = {
        Name = "TicTacToe VPC Gateway"
    }
}

# Konfiguracja tablicy routowania - wpuszcza cały ruch przychodzący do VPC
resource "aws_route_table" "ttt_routing" {
    vpc_id = aws_vpc.ttt_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ttt_gateway.id
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.ttt_gateway.id
    }

    tags = {
        Name = "TicTacToe VPC Routing Table"
    }
}

# Podłączenie tablicy routingu do podsieci, w której będzie się znajdować
# instancja EC2
resource "aws_route_table_association" "ttt_routing_assoc" {
    subnet_id = aws_subnet.ttt_subnet_pub.id
    route_table_id = aws_route_table.ttt_routing.id
}

# Konfiguracja firewalla dla instancji EC2
resource "aws_security_group" "ttt_security_group" {
    name_prefix = "ttt_security_group"
    vpc_id = aws_vpc.ttt_vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
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

# Klucz publiczny do autoryzacji logowania przez SSH
resource "aws_key_pair" "ttt_kp" {
    key_name = "pc"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4QJZJ+AkijoThPe+disNSVrtuuS7d2W9sq7ih0fU6RM/rkFuavhG4DdXrsGIIQJUKFY5uNSGqTcdum9Ns9EhedXrKq0W8UJkgpjAkGfQBYwj575qsvh/83wWk9SeKEVRFhHxHhotpmNvpPN2F0eB8R0gidKJf46eNQ3BH9/ULHAj9ZH/hoXODWRAh5GPJ/Y14qpiJqP2bVqPgebU5XbZ6s2DiuVqrwSZ5sX1uRyJcKsJs9IcEAsrc4PGUKkLQ7MRZ+cdrM3hwju0Gj/7ulLIBDWhpWk6jvssadtj14eft3NEEbJeX6ss9Ej/8uYMHqHxMe0fcvVe5vuvXAOg0avh5OKDaoRHKxA5I/IEryVo3385jEFPtV0RhYSnJWdiBYUufG3LZnSAV4eAdclB7See25rK5S16BvkiX7nGMCN8h3ZkXW3C04D5FFq9p+PWi9LvCmZd+sS8VwcpL67xFGkId8srMl4hb0e52k3G4Vz4wouCNLpnTEI3z8rM5Xuj0vo0= lukasz@DESK-X570"
}

# Instancja EC2
resource "aws_instance" "ttt_ec2" {
    ami = "ami-0e001c9271cf7f3b9" # Ubuntu 22.04 LTS
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
        sudo apt-get -y update

        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Run the app
        cd /var
        sudo mkdir app
        cd app
        sudo git clone https://github.com/swiszczoo/chmura1.git
        cd chmura1
        sudo docker compose -f docker-compose-prod.yml up -d
    EOF

    subnet_id = aws_subnet.ttt_subnet_pub.id
    associate_public_ip_address = true

    vpc_security_group_ids = [
        aws_security_group.ttt_security_group.id,
    ]

    tags = {
        Name = "TicTacToe"
    }
}

# Na wyjściu chcemy otrzymać publiczny adres IP instancji
output "public_ip" {
    value = aws_instance.ttt_ec2.public_ip
}
