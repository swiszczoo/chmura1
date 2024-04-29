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

resource "aws_elastic_beanstalk_application" "tictactoe" {
    name        = "tictactoe"
    description = "tictactoe-game"
}

resource "aws_s3_bucket" "ttt" {
    bucket = "ttt-docker"
}

resource "aws_s3_object" "ttt_code" {
    bucket = aws_s3_bucket.ttt.bucket
    key = "ttt-code.zip"
    source = "app.zip"
}

resource "aws_elastic_beanstalk_application_version" "ttt-version" {
  application = aws_elastic_beanstalk_application.tictactoe.name
  description = "TicTacToe version"
  bucket      = aws_s3_bucket.ttt.bucket
  key         = aws_s3_object.ttt_code.key
  name        = "V1.0" 
}

resource "aws_elastic_beanstalk_environment" "ttt-env" { 
  name = "TicTacToe-env"
  application = aws_elastic_beanstalk_application.tictactoe.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.1 running Docker"
  tier = "WebServer"
  cname_prefix = "tictactoe-game"
  version_label = aws_elastic_beanstalk_application_version.ttt-version.name

  setting { 
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "vockey"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "LabInstanceProfile"
  }
  setting { 
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.micro"
  }
  setting { 
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = aws_security_group.ttt_security_group.id
  }
  setting { 
    namespace = "aws:ec2:instances"
    name = "SupportedArchitectures"
    value = "x86_64"
  }
  setting { 
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = aws_vpc.ttt_vpc.id
  }
  setting { 
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = aws_subnet.ttt_subnet_pub.id
  }
  setting { 
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }
  setting { 
    namespace = "aws:elasticbeanstalk:environment"
    name = "EnvironmentType"
    value = "SingleInstance"
  }
}

output "public_address" {
    value = aws_elastic_beanstalk_environment.ttt-env.endpoint_url
}
