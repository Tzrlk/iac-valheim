import { Construct } from 'constructs';
import { AwsSecretInSecretsManager } from 'lib/AwsSecretInSecretsManager';
import { DataDockerImage } from 'provider/docker';
import { range } from 'ramda';
import { SecretsmanagerSecret } from 'provider/aws/secretsmanager';
import {
	ECSContainerDefinition as EcsContainerDefinition,
	KeyValuePair as EcsKeyValuePair,
} from 'lib/json/ecs-container-definition.schema'
import Dict = NodeJS.Dict;

const valheimPorts = {
	ddns: 9002,
	max: 2458,
	min: 2456,
	status: 80,
	super: 9001,
};

function formatEnvironment(vars: Dict<string>): EcsKeyValuePair[] {
	return Object.entries(vars).map(function([ key, value ]) {
		return { name: key, value: value?.toString() || '' }
	})
}

export class EcsTaskValheim extends Construct {
	constructor(scope: Construct, readonly config: EcsTaskValheim.Config) {
		super(scope, 'Valheim');
	}

	readonly dockerImage = new DataDockerImage(this, "Valheim", {
		name: "tzrlk/valheim-server",
	})

	readonly serverPass = new AwsSecretInSecretsManager(this, 'ServerPass', {
		name:        'valheim-server-pass',
		description: 'The password used to access the valheim server.',
		secret:      () => this.node.tryGetContext('ServerPass') as string
	})

	readonly container: EcsContainerDefinition = {
		name: "valheim",
		cpu: this.cpu,
		memory: this.memory,
		environment: formatEnvironment({
			SERVER_NAME: "Bunnings",
			SERVER_PORT: valheimPorts.min.toString(),
			WORLD_NAME: "Bunnings",
			BACKUPS_IF_IDLE: "false",
			BACKUP_CRON: "@hourly",
			STATUS_HTTP: "true",
			STATUS_HTTP_PORT: valheimPorts.status.toString(),
			SUPERVISOR_HTTP: "true",
			SUPERVISOR_HTTP_PORT: valheimPorts.super.toString(),
			ADMINLIST_IDS: this.config.adminList.join(" "),
			DNS_1: "10.0.0.2",
			DNS_2: "10.0.0.2",
			TZ: "Pacific/Auckland",
		}),
		essential: true,
		healthCheck: {
			command: [ "CMD-SHELL", "/healthcheck.sh" ],
			interval: 30,
			retries: 3,
			startPeriod: 300,
			timeout: 5,
		},
		image: this.dockerImage.repoDigest,
		linuxParameters: {
			initProcessEnabled: true,
		},
		logConfiguration: {
			logDriver: "awslogs",
			options: {
				awslogsGroup: this.config.loggingGroup,
				awslogsRegion: "ap-southeast-2",
				awslogsStreamPrefix: "server",
			},
		},
		portMappings: [ ...range(valheimPorts.min, valheimPorts.max), valheimPorts.super, valheimPorts.status ]
				.map((port) => { return { hostPort: port, containerPort: port, protocol: "tcp" } }),
		secrets: [
			{
				name: "SERVER_PASS",
				valueFrom: this.serverPass.secret.arn,
			},
		],
	}

	get cpu(): number { return this.config.cpu }
	get memory(): number { return this.config.memory }

}

export module EcsTaskValheim {
	export interface Config {
		readonly cpu: number;
		readonly memory: number;
		readonly loggingGroup: string;
		readonly adminList: string[]
	}
}

export default EcsTaskValheim
