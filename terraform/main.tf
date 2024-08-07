provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "puppet_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "AppVPC"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id            = aws_vpc.puppet_vpc.id
    cidr_block        = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
        Name = "PublicSubnet"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id            = aws_vpc.puppet_vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "PrivateSubnet"
    }
}

resource "aws_security_group" "web_sg" {
    vpc_id = aws_vpc.puppet_vpc.id

    ingress {
        from_port   = 80                                        
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db_sg" {
    vpc_id = aws_vpc.puppet_vpc.id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
       cidr_blocks = ["10.0.2.0/24"]
    }
}

resource "aws_instance" "web_instance" {
  ami               = "ami-03c951bbe993ea087"
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.public_subnet.id
  security_groups   = [aws_security_group.web_sg.id]
  monitoring        = true

    user_data = <<-EOF
              #!/bin/bash
              # Update the system
              yum update -y
              
              # Install Puppet Agent
              rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
              yum install -y puppet-agent
              # Note: Puppet is installed but not configured to connect to a Puppet Master

              # Install Chef Client
              curl -L https://omnitruck.chef.io/install.sh | bash
              # Note: Chef Client is installed but not configured to connect to a Chef Server

              # Additional configuration can be performed manually later
              EOF

  tags = {
    Name = "WebInstance"
  }
}

resource "aws_db_instance" "app_db" {
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t2.micro"
  db_name               = "appdb"
  username              = "admin"
  password              = var.db_password
  parameter_group_name  = "default.mysql8.0"
  db_subnet_group_name  = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  multi_az              = true
  storage_encrypted     = true

    tags = {
        Name = "AppDB"
    }
}

resource "aws_db_subnet_group" "db_subnet_group" {
    subnet_ids = [aws_subnet.private_subnet.id]

    tags = {
        Name = "MyDBSubnetGroup"
    }
}

output "web_instance_ip" {
    value = aws_instance.web_instance.public_ip
}

output "db_instance_endpoint" {
    value = aws_db_instance.app_db.endpoint
}