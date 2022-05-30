# Security group and NACL config.

resource "aws_security_group" "Cluster" {
	vpc_id = aws_vpc.Vpc.id
	name   = "cluster"
	tags   = {
		Cost = "Free"
	}
}

resource "aws_security_group_rule" "AnywhereToClusterHttp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "tcp"
	to_port           = 80
	from_port         = 80
}
resource "aws_security_group_rule" "AnywhereToClusterHttps" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "tcp"
	to_port           = 443
	from_port         = 443
}
resource "aws_security_group_rule" "AnywhereToClusterDnsTcp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "tcp"
	to_port           = 53
	from_port         = 53
}
resource "aws_security_group_rule" "AnywhereToClusterDnsUdp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "udp"
	to_port           = 53
	from_port         = 53
}
resource "aws_security_group_rule" "AnywhereToClusterValheimUdp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "udp"
	from_port         = local.ValheimPorts.Min
	to_port           = local.ValheimPorts.Max
}
resource "aws_security_group_rule" "AnywhereToClusterValheimTcp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "tcp"
	from_port         = local.ValheimPorts.Min
	to_port           = local.ValheimPorts.Max
}
resource "aws_security_group_rule" "ClusterToAnywhereDnsTcp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "tcp"
	from_port         = 53
	to_port           = 53
}
resource "aws_security_group_rule" "ClusterToAnywhereDnsUdp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "udp"
	from_port         = 53
	to_port           = 53
}
resource "aws_security_group_rule" "ClusterToAnywhereHttp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "tcp"
	from_port         = 80
	to_port           = 80
}
resource "aws_security_group_rule" "ClusterToAnywhereHttps" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "tcp"
	from_port         = 443
	to_port           = 443
}
resource "aws_security_group_rule" "ClusterToAnywhereValheimUdp" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "udp"
	from_port         = local.ValheimPorts.Min
	to_port           = local.ValheimPorts.Max
}

resource "aws_network_acl" "Firewall" {
	vpc_id     = aws_vpc.Vpc.id
	subnet_ids = [ aws_subnet.Subnet.id ]
	ingress { # Valheim UDP
		rule_no    = 10
		protocol   = "udp"
		from_port  = local.ValheimPorts.Min
		to_port    = local.ValheimPorts.Max
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # Valheim TCP
		rule_no    = 15
		protocol   = "tcp"
		from_port  = local.ValheimPorts.Min
		to_port    = local.ValheimPorts.Max
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # valheim status
		rule_no    = 20
		protocol   = "tcp"
		from_port  = 80
		to_port    = 80
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # Ephemeral responses
		rule_no    = 30
		protocol   = "tcp"
		from_port  = 1024
		to_port    = 65535
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # DNS TCP
		rule_no    = 40
		protocol   = "tcp"
		from_port  = 53
		to_port    = 53
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # DNS UDP
		rule_no    = 45
		protocol   = "udp"
		from_port  = 53
		to_port    = 53
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # HTTP
		rule_no    = 10
		protocol   = "tcp"
		from_port  = 80
		to_port    = 80
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # HTTPS
		rule_no    = 20
		protocol   = "tcp"
		from_port  = 443
		to_port    = 443
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # DNS
		rule_no    = 30
		protocol   = "tcp"
		from_port  = 53
		to_port    = 53 
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # DNS UDP
		rule_no    = 35
		protocol   = "udp"
		from_port  = 53
		to_port    = 53
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # Ephemeral responses
		rule_no    = 40
		protocol   = "tcp"
		from_port  = 1024
		to_port    = 65535
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	tags = {
		Cost = "Free"
	}
}