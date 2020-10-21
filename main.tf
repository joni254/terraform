
# Configure the AWS Provider
provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.access_secret
}

# creating a vpc
resource "aws_vpc" "erp_vpc" {
    cidr_block = var.vpcCIDRblock
    tags = {
      "Name" = "Erp_Vpc"
    }
  
}

# create a subnet
resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.erp_vpc.id
  cidr_block = var.subnetCIDRblock

  tags = {
    Name = "Erp_subnet"
  }
}

#Add an internet gateway
resource "aws_internet_gateway" "default_gateway" {
    vpc_id = aws_vpc.erp_vpc.id
  
}


# Routing Table
resource "aws_route_table" "default_route_table" {
  vpc_id = aws_vpc.erp_vpc.id

  route {
    cidr_block = var.routeCIDRblock
    gateway_id = aws_internet_gateway.default_gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.default_gateway.id
  }

  tags = {
    Name = "default_route"
  }
}
#route_table association
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.default_route_table.id
}

# A security group node

resource "aws_security_group" "Webserver_node" {
  vpc_id = aws_vpc.erp_vpc.id

  ingress {
    description = "http traffic"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.ingressCIDRblock]
    
  }

  ingress {
    description ="https traffic"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.ingressCIDRblock]
    
  }
  ingress {
    description = "ssh traffic"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ingressCIDRblock]
    
  }
  egress {
    description = "Allow all ports"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.egressCIDRblock]
    
  }
tags = {
  Name = "Webserver-node"
  description = "A Sec node for apache webserver"
}
}
# create a network inteface controller
resource "aws_network_interface""Internet_interface"{
  subnet_id = aws_subnet.main_subnet.id
  private_ips = ["10.0.1.100"]
  security_groups = [aws_security_group.Webserver_node.id]

}
# Secure an elastic IP for your EC2 instance

resource "aws_eip""eip"{
  vpc = true
  network_interface = aws_network_interface.Internet_interface.id
  associate_with_private_ip = "10.0.1.100"

  depends_on = [aws_internet_gateway.default_gateway]

}
  
# create an ubuntu server instance
resource "aws_instance" "webserver" {
  ami = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = var.availabilityZone
  key_name = "my_key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.Internet_interface.id
  }

  tags = {
    "Name" = "Apache server"

  }

  # run scripts to install apache setup
  user_data = <<-EOF
              #!bin/bash
              sudo apt-get update -y
              sudo apt-get install -y apache2
              sudo systemctl start apache2
              sudo systemctl enable apache2  
              sudo bash -c 'echo Apache installed successfully! >/var/www/html/index.html'
              EOF


  
} 
