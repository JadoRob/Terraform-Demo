provider "aws" {
  profile                   = "default"
  region                    = "us-east-1"
}

# Create a VPC named Demo VPC
resource "aws_vpc" "vpc_demo" {
  cidr_block                = "192.168.0.0/16" # Required
  instance_tenancy          = "default" 
  tags = {
    Name                    = "Demo VPC"
  }
  enable_dns_hostnames      = true
}

# Create a public subnet named public_subnet in AZ us-east-1a
resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.vpc_demo.id # Required
    cidr_block              = "192.168.0.0/24" # Required
    availability_zone       = "us-east-1a" # Required
    map_public_ip_on_launch = true
    tags = {
        Name                = "Public Subnet"
    }
}

# Create a private subnet named private_subnet in AZ us-east-1a
resource "aws_subnet" "private_subnet" {
    vpc_id                  = aws_vpc.vpc_demo.id # Required
    cidr_block              = "192.168.1.0/24" # Required
    availability_zone       = "us-east-1a" # Required
    tags = {
        Name                = "Private Subnet"
    }
}

# # Create a public subnet named public_subnet in AZ us-east-1b
# resource "aws_subnet" "public_subnet" {
#     vpc_id                  = aws_vpc.vpc_demo.id
#     cidr_block              = "192.168.2.0/24"
#     availability_zone       = "us-east-1b"
#     map_public_ip_on_launch = true
#     tags = {
#         Name                = "Public Subnet"
#     }
# }

# # Create a private subnet named private_subnet in AZ us-east-1b
# resource "aws_subnet" "private_subnet" {
#     vpc_id                  = aws_vpc.vpc_demo.id # Required
#     cidr_block              = "192.168.3.0/24" # Required
#     availability_zone       = "us-east-1b" # Required
#     tags = {
#         Name                = "Private Subnet"
#     }
# }

# Create an Internet Gateway named Demo Internet Gateway
resource "aws_internet_gateway" "demo_igw" {
    depends_on = [ 
        aws_vpc.vpc_demo,
        aws_subnet.public_subnet
     ]
     vpc_id                 = aws_vpc.vpc_demo.id # Required
     tags = {
         Name               = "Demo Internet Gateway"
     }
}

# Create a Route Table named Public Route Table
# also creates a route in the route table with desitination 0.0.0.0/0
# and target the Internet Gateway
resource "aws_route_table" "public_rt" {
    depends_on = [ 
        aws_vpc.vpc_demo,
        aws_internet_gateway.demo_igw
     ]
     vpc_id                 = aws_vpc.vpc_demo.id # Required

     route {
       cidr_block           = "0.0.0.0/0"
       gateway_id           = aws_internet_gateway.demo_igw.id
     }

     tags = {
         Name               = "Public Route Table"
     }
}

resource "aws_route_table_association" "public_rt_public_subnet_association" {
    depends_on = [ 
        aws_subnet.public_subnet,
        aws_route_table.public_rt
     ]

     subnet_id              = aws_subnet.public_subnet.id
     route_table_id         = aws_route_table.public_rt.id
}

# Create an EIP named EIP for NAT
resource "aws_eip" "EIP_for_NAT_Gateway" {
    depends_on = [ 
        aws_route_table_association.public_rt_public_subnet_association
     ]

     vpc                    = true

     tags = {
         Name               = "EIP for NAT"
     }
}

# Create the Nat Gateway named Demo NAT Gateway
resource "aws_nat_gateway" "demo_nat" {
    depends_on = [ 
        aws_eip.EIP_for_NAT_Gateway
     ]

     allocation_id          = aws_eip.EIP_for_NAT_Gateway.id
     subnet_id              = aws_subnet.public_subnet.id

     tags = {
         Name               = "Demo Nat Gateway"
     }
}

# Create a Private Route Table named Private Route Table
# Create a route in the route table with destination 0.0.0.0/0 and target the NAT Gateway
resource "aws_route_table" "private_rt" {
    depends_on = [ 
        aws_vpc.vpc_demo,
        aws_nat_gateway.demo_nat
     ]
     vpc_id                 = aws_vpc.vpc_demo.id # Required

     route {
       cidr_block           = "0.0.0.0/0"
       gateway_id           = aws_nat_gateway.demo_nat.id
     }

     tags = {
         Name               = "Private Route Table"
     }
}

# Create an association between the private subnet and the private RT
resource "aws_route_table_association" "private_rt_private_subnet_association" {
    depends_on = [ 
        aws_subnet.private_subnet,
        aws_route_table.private_rt
     ]

     subnet_id              = aws_subnet.private_subnet.id
     route_table_id         = aws_route_table.private_rt.id
}