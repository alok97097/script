# Create a t3a.micro ec2 instance in private subnet AWS or Azure instances using Terraform scripts.
# VPC, Subnet, RouteTable, SecurityGroup, Access Key and EC2 machines should all be created via terraform.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
# Configure aws cli with access key and secret key
# or pass access key and secret in script
provider "aws" {
    #access_key = "${var.aws_access_key}"
    #secret_key = "${var.aws_secret_key}"
    region = "us-east-2"
}

# Create VPC
resource "aws_vpc" "demo_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      Name = "Default-VPC"
    }
}

# Create Subnet
resource "aws_subnet" "demo_sub" {
    vpc_id                          = aws_vpc.demo_vpc.id
    availability_zone               =  "us-east-2a"
    cidr_block                      = "10.0.0.0/24"
    map_public_ip_on_launch         = true
    tags                            = {
        Name = "Public-Subnet"
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
    vpc_id   = aws_vpc.demo_vpc.id
    tags     = {
        Name = "IGW-Default"
    }
}

# Create Route Table
resource "aws_route_table" "demo_rt" {
    vpc_id  = aws_vpc.demo_vpc.id
    route  {
            cidr_block   = "0.0.0.0/0"
            gateway_id   = aws_internet_gateway.demo_igw.id
        }
    
    tags             = {
        "Name" = "Default-RT"
    }

}

# RouteTable Association
resource "aws_route_table_association" "demo_rt_sub" {
    route_table_id = aws_route_table.demo_rt.id
    subnet_id      = aws_subnet.demo_sub.id
}

# Create Security Group
resource "aws_security_group" "demo_sg" {
    name        = "ec2-sg"
    vpc_id      = aws_vpc.demo_vpc.id
    description = "SSH ,HTTP, and HTTPS"
    egress {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = "default egress"
            from_port        = 0
            protocol         = "-1"
            to_port          = 0
            self             = false
        }
    
    ingress     = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = "HTTP access"
            from_port        = 80
            protocol         = "tcp"
            to_port          = 80
            prefix_list_ids  = null
            ipv6_cidr_blocks = null
            security_groups  = null
            self             = false  
        },
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = "HTTPS access"
            from_port        = 443
            protocol         = "tcp"
            to_port          = 443   
            prefix_list_ids  = null
            ipv6_cidr_blocks = null
            security_groups  = null
            self             = false        
        },
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = "SSH access"
            from_port        = 22
            protocol         = "tcp"
            security_groups  = []
            to_port          = 22
            prefix_list_ids  = null
            ipv6_cidr_blocks = null
            security_groups  = null
            self             = false   
        },
    ]

    tags = {
        Name = "EC2-SG"
    }
}

# Create EC2
resource "aws_instance" "Ubuntu" {
    ami           = "ami-00399ec92321828f5"
    instance_type = " t3a.micro"
    key_name = aws_key_pair.keypair.key_name

    subnet_id = aws_subnet.demo_sub.id
    vpc_security_group_ids = [aws_security_group.demo_sg.id]

    tags = {
        Name ="Ubuntu"
    }

    root_block_device {
        delete_on_termination = true
        encrypted             = false
        iops                  = 100
        volume_size           = 8
    }
}

resource "aws_key_pair" "keypair" {
    key_name = "ubuntu-key"
    public_key = "ssh-rsa <add public key here>"
}