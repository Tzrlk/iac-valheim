# Security group and NACL config.

resource "aws_security_group" "Cluster" {
	vpc_id = aws_vpc.Vpc.id
	name   = "cluster"
	tags   = {
		Cost = "Free"
	}
}
resource "aws_security_group" "Storage" {
	vpc_id = aws_vpc.Vpc.id
	name   = "storage"
	tags   = {
		Cost = "Free"
	}
}


locals {
	EfsPort = 2049
	EfsPortMin = min(local.EfsPort, values(local.EfsAccess)[*].port...)
	EfsPortMax = max(local.EfsPort, values(local.EfsAccess)[*].port...)
}
resource "aws_security_group_rule" "ClusterToStorageEfs" {
	security_group_id        = aws_security_group.Cluster.id
	source_security_group_id = aws_security_group.Storage.id
	type                     = "egress"
	protocol                 = "tcp"
	from_port                = local.EfsPortMin
	to_port                  = local.EfsPortMax
}
resource "aws_security_group_rule" "StorageFromClusterEfs" {
	security_group_id        = aws_security_group.Storage.id
	source_security_group_id = aws_security_group.Cluster.id
	type                     = "ingress"
	protocol                 = "tcp"
	from_port                = local.EfsPortMin
	to_port                  = local.EfsPortMax
}
resource "aws_security_group_rule" "StorageToStorageEfs" {
	security_group_id        = aws_security_group.Storage.id
	source_security_group_id = aws_security_group.Storage.id
	type                     = "egress"
	protocol                 = "tcp"
	from_port                = local.EfsPortMin
	to_port                  = local.EfsPortMax
}
resource "aws_security_group_rule" "StorageFromStorageEfs" {
	security_group_id        = aws_security_group.Storage.id
	source_security_group_id = aws_security_group.Storage.id
	type                     = "ingress"
	protocol                 = "tcp"
	from_port                = local.EfsPortMin
	to_port                  = local.EfsPortMax
}

resource "aws_security_group_rule" "AnywhereToClusterValheim" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "ingress"
	protocol          = "udp"
	from_port         = local.ValheimPorts.Min
	to_port           = local.ValheimPorts.Max
}
resource "aws_security_group_rule" "ClusterValheimToAnywhere" {
	security_group_id = aws_security_group.Cluster.id
	cidr_blocks       = [ "0.0.0.0/0" ]
	type              = "egress"
	protocol          = "tcp"
	from_port         = 443
	to_port           = 443
}

resource "aws_network_acl" "Firewall" {
	vpc_id     = aws_vpc.Vpc.id
	subnet_ids = [ aws_subnet.Subnet.id ]
	ingress { # Valheim
		rule_no    = 10
		protocol   = "udp"
		from_port  = local.ValheimPorts.Min
		to_port    = local.ValheimPorts.Max
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	ingress { # EFS
		rule_no    = 20
		protocol   = "tcp"
		from_port  = local.EfsPortMin
		to_port    = local.EfsPortMax
		cidr_block = aws_subnet.Subnet.cidr_block
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
	ingress { # DNS
		rule_no    = 40
		protocol   = "tcp"
		from_port  = 53
		to_port    = 53
		cidr_block = "0.0.0.0/0"
		action     = "allow"
	}
	egress { # EFS
		rule_no    = 10
		protocol   = "tcp"
		from_port  = local.EfsPortMin
		to_port    = local.EfsPortMax
		cidr_block = aws_subnet.Subnet.cidr_block
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