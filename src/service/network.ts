import { Construct } from 'constructs';
import * as aws from 'provider/aws';
import {
	InternetGateway, NetworkAcl,
	RouteTable,
	RouteTableAssociation,
	SecurityGroup,
	SecurityGroupRule, Subnet,
	Vpc,
} from 'provider/aws/vpc';
import { DataHttp } from 'provider/http';

export module ValheimServiceNetwork {
	export interface Config {
		ddns: {
			port: number
		},
		valheim: {
			ports: {
				status: number,
				super: number,
				min: number,
				max: number,
			}
		}
	}
}

export default class ValheimServiceNetwork extends Construct {

	constructor(scope: Construct, private readonly config: ValheimServiceNetwork.Config) {
		super(scope, 'Network');
	}

	readonly vpc = new Vpc(this, "Vpc", {
		cidrBlock: "10.0.0.0/24",
		enableDnsHostnames: true,
		enableDnsSupport: true,
		tags: {
			cost: "Free",
		},
	});

	readonly internetGateway = new InternetGateway(this, "Internet", {
		vpcId: this.vpc.id,
		tags: {
			cost: "Free",
		},
	});

	readonly routeTable = new RouteTable(this, "Routing", {
		vpcId: this.vpc.id,
		route: [{
			cidrBlock: "0.0.0.0/0",
			gatewayId: this.internetGateway.id,
		}],
		tags: {
			cost: "Free",
		},
	});

	readonly securityGroupCluster = new SecurityGroup(this, "Cluster", {
		vpcId: this.vpc.id,
		name:  "cluster",
		tags: {
			cost: "Free",
		},
	}).also((group) => {

		// Nested partial construction of rules. Maybe.

		new SecurityGroupRule(this, "AnywhereToClusterDdns", {
			cidrBlocks: [`${this.externalIp}/32`],
			fromPort: this.config.ddns.port,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: this.config.ddns.port,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterDnsTcp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 53,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: 53,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterDnsUdp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 53,
			protocol: "udp",
			securityGroupId: group.id,
			toPort: 53,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterHttps", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 443,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: 443,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterStatus", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: this.config.valheim.ports.status,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: this.config.valheim.ports.status,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterSuper", {
			cidrBlocks: [`${this.externalIp.body.trim()}/32`],
			fromPort: this.config.valheim.ports.super,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: this.config.valheim.ports.super,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterValheimTcp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: this.config.valheim.ports.min,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: this.config.valheim.ports.max,
			type: "ingress",
		});
		new SecurityGroupRule(this, "AnywhereToClusterValheimUdp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: this.config.valheim.ports.min,
			protocol: "udp",
			securityGroupId: group.id,
			toPort: this.config.valheim.ports.max,
			type: "ingress",
		});
		new SecurityGroupRule(this, "ClusterToAnywhereDnsTcp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 53,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: 53,
			type: "egress",
		});
		new SecurityGroupRule(this, "ClusterToAnywhereDnsUdp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 53,
			protocol: "udp",
			securityGroupId: group.id,
			toPort: 53,
			type: "egress",
		});
		new SecurityGroupRule(this, "ClusterToAnywhereHttp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 80,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: 80,
			type: "egress",
		});
		new SecurityGroupRule(this, "ClusterToAnywhereHttps", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: 443,
			protocol: "tcp",
			securityGroupId: group.id,
			toPort: 443,
			type: "egress",
		});
		new SecurityGroupRule(this, "ClusterToAnywhereValheimUdp", {
			cidrBlocks: ["0.0.0.0/0"],
			fromPort: this.config.valheim.ports.min,
			protocol: "udp",
			securityGroupId: group.id,
			toPort: this.config.valheim.ports.max,
			type: "egress",
		});
	});

	// const localExternalIp = dataHttpExternalIp.body.trim();
	readonly externalIp = new DataHttp(this, "ExternalIp", {
		url: "https://ifconfig.me",
	});

	readonly serviceSubnet = new Subnet(this, "Subnet", {
		cidrBlock: this.vpc.cidrBlock,
		mapPublicIpOnLaunch: true,
		tags: {
			cost: "Free",
		},
		vpcId: this.vpc.id,
	});

	readonly subnetRouting = new RouteTableAssociation(this, "SubnetRouting", {
		routeTableId: this.routeTable.id,
		subnetId:     this.serviceSubnet.id,
	});

	readonly nacl = new NetworkAcl(this, "Firewall", {
		egress: [
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 80,
				protocol: "tcp",
				ruleNo: 10,
				toPort: 80,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 443,
				protocol: "tcp",
				ruleNo: 20,
				toPort: 443,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 53,
				protocol: "tcp",
				ruleNo: 30,
				toPort: 53,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 53,
				protocol: "udp",
				ruleNo: 35,
				toPort: 53,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 1024,
				protocol: "tcp",
				ruleNo: 40,
				toPort: 65535,
			},
		],
		ingress: [
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: this.config.valheim.ports.min,
				protocol: "udp",
				ruleNo: 10,
				toPort: this.config.valheim.ports.max,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: this.config.valheim.ports.min,
				protocol: "tcp",
				ruleNo: 15,
				toPort: this.config.valheim.ports.max,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: this.config.valheim.ports.status,
				protocol: "tcp",
				ruleNo: 20,
				toPort: this.config.valheim.ports.status,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 1024,
				protocol: "tcp",
				ruleNo: 30,
				toPort: 65535,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 53,
				protocol: "tcp",
				ruleNo: 40,
				toPort: 53,
			},
			{
				action: "allow",
				cidrBlock: "0.0.0.0/0",
				fromPort: 53,
				protocol: "udp",
				ruleNo: 45,
				toPort: 53,
			},
		],
		subnetIds: [this.serviceSubnet.id],
		tags: {
			cost: "Free",
		},
		vpcId: this.vpc.id,
	});

}
