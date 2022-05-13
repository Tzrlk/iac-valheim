# Set up a VPC with one tiny public subnet.

resource "aws_vpc" "Vpc" {
	cidr_block           = "10.0.0.0/24"
	enable_dns_support   = true
	enable_dns_hostnames = true
	tags                 = {
		Cost = "Free"
	}
}

resource "aws_subnet" "Subnet" {
	vpc_id                  = aws_vpc.Vpc.id
	cidr_block              = aws_vpc.Vpc.cidr_block
	map_public_ip_on_launch = true
	tags                    = {
		Cost = "Free"
	}
}
resource "aws_route_table" "Routing" {
	vpc_id = aws_vpc.Vpc.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.Internet.id
	}
	tags = {
		Cost = "Free"
	}
}
resource "aws_route_table_association" "SubnetRouting" {
	route_table_id = aws_route_table.Routing.id
	subnet_id      = aws_subnet.Subnet.id
}

resource "aws_internet_gateway" "Internet" {
	vpc_id = aws_vpc.Vpc.id

	tags = {
		Cost = "Free"
	}
}