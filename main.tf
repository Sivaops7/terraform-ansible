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


# Create VPC 
resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "main"
  }
}

# Create cutom route table

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"  //allow all traffic by this ip
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "MY-VPC-PUB-RT"
  }
}

# Create a subnet

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MY-VPC-PUB-SUB"
  }
}

# Assocoate subnet with Route tables

resource "aws_route_table_association" "pub-ass" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

# Create security Group to allow port 22 80 443

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
    ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
    
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  //everyone can access
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  
  }

  tags = {
    Name = "my-vpc-sg"
  }
}

#create a network interface with an ip in the subnet
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.pubsub.id //paste from subnet
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_all.id]  //copy from security group above
 
}
//8.assign an elastic ip to network interface created in step 7
resource "aws_eip" "one" {

  domain		    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id // copy from nic above
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.tigw]
}
//print server ip in console
output "server_public_ip" {
  value = aws_eip.one.public_ip
  
}

resource "aws_instance" "app-server" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"  //reason to hardcode avail zone so that subnet & interface will be in same zone
  key_name = "terraform-key"

  network_interface {
    device_index = 0  // 0 is first network associated with this device or instance
    network_interface_id = aws_network_interface.web-server-nic.id
    
  }

    tags = {
      Name= "app-server"
   }
}
output "server_private_ip" {
  value = aws_instance.app-server.private_ip
  
  
}

output "server_id" {
  
  value = aws_instance.app-server.id
  
}
