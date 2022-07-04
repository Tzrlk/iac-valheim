import { Construct } from 'constructs';
import { ECSContainerDefinition } from 'lib/json/ecs-container-definition.schema';

const dnsUpdaterConfig = {
	settings: [
		{
			domain: "jumpingcrab.com",
			host: "vikongs",
			ipVersion: "ipv4",
			provider: "freedns",
			token: "2tuXUBhXKexACEfMZKKBjuy8",
		},
	],
};

export class EcsTaskDnsupdater extends Construct {
	constructor(scope: Construct,
	            private readonly config: EcsTaskDnsupdater.Config) {
		super(scope, 'DnsUpdater');
	}

	readonly container: ECSContainerDefinition = {
		cpu: this.config.resources.cpu,
		environment: [
			{
				name: "CONFIG",
				value: JSON.stringify(dnsUpdaterConfig),
			},
			{
				name: "LISTENING_PORT",
				value: this.config.ddns.toString(),
			},
			{
				name: "TZ",
				value: "Pacific/Auckland",
			},
		],
		essential: false,
		healthCheck: {
			command: ["CMD-SHELL", "curl -f http://localhost:9999"],
			interval: 30,
			retries: 3,
			startPeriod: 300,
			timeout: 5,
		},
		image: "qmcgaw/ddns-updater:latest",
		linuxParameters: {
			initProcessEnabled: true,
		},
		logConfiguration: {
			logDriver: "awslogs",
			options: {
				awslogsGroup: this.config.loggingGroup,
				awslogsRegion: "ap-southeast-2",
				awslogsStreamPrefix: "ddns",
			},
		},
		memory: this.config.resources.memory,
		mountPoints: [],
		name: "dnsupdater",
		portMappings: [
			{
				containerPort: valheimPorts.ddns,
				hostPort: valheimPorts.ddns,
				protocol: "tcp",
			},
		],
		volumesFrom: [],
	}

}

export module EcsTaskDnsupdater {
	export class Config {
		resources: {
			cpu:    number,
			memory: number,
		}
	}
}

export default EcsTaskDnsupdater
