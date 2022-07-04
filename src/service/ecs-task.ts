import { Construct } from 'constructs';
import { EcsService, EcsTaskDefinition } from 'provider/aws/ecs';
import { IamRole } from 'provider/aws/iam';
import EcsTaskDnsupdater from './ecs-task-dnsupdater';
import EcsTaskValheim from './ecs-task-valheim';

export class ValheimEcsTask extends Construct {

	constructor(scope: Construct, private readonly config: ValheimEcsTask.Config) {
		super(scope, 'EcsTask');
	}

	readonly taskResFactors = {
		cpu: 2,
		mem: 6,
	};

	readonly dnsupdater = new EcsTaskDnsupdater(this, {
		resources: {
			cpu:    24 * this.taskResFactors.cpu,
			memory: 24 * this.taskResFactors.mem,
		}
	})

	readonly valheim = new EcsTaskValheim(this, {
		cpu: 1000 * this.config.cpuFactor,
		memory: 1000 * this.config.memoryFactor,
		adminList: [],
		loggingGroup: ''
	})

	private readonly ecsTrustPolicyJson = JSON.stringify({
		//
	})

	readonly execRole = new IamRole(this, "ValheimExec", {
		assumeRolePolicy: this.ecsTrustPolicyJson,
		managedPolicyArns: [
			this.config.execPolicyArn,
			this.config.secretPolicyArn,
			this.config.ssmPolicyArn,
			this.config.storagePolicyArn,
			this.config.loggingPolicyArn,
		],
		tags: {
			cost: "Free",
		},
	});

	readonly taskRole = new IamRole(this, "ValheimTask", {
		assumeRolePolicy: this.ecsTrustPolicyJson,
		managedPolicyArns: [
			this.config.secretPolicyArn,
			this.config.execPolicyArn,
			this.config.storagePolicyArn,
			this.config.loggingPolicyArn,
		],
		tags: {
			cost: "Free",
		},
	});

	readonly taskDef = new EcsTaskDefinition(this, "Tasks", {
		containerDefinitions: JSON.stringify([
			this.valheim.container,
			this.dnsupdater.container,
		]),
		cpu: ( this.valheim.container.cpu + this.valheim.container.memory ).toString(),
		executionRoleArn: this.execRole.arn,
		family: "valheim",
		memory: ( this.valheim.container.memory + this.dnsupdater.container.memory ).toString(),
		networkMode: "awsvpc",
		requiresCompatibilities: ["FARGATE"],
		taskRoleArn: this.taskRole.arn,
		tags: {
			cost: "Free",
		},
	});

	readonly service = new EcsService(this, "Valheim_58", {
		cluster: this.config.clusterId,
		name: "valheim",
		launchType: "FARGATE",
		taskDefinition: this.taskDef.id,
		deploymentMinimumHealthyPercent: 0,
		deploymentMaximumPercent: 100,
		desiredCount: this.config.taskEnabled ? 1 : 0,
		forceNewDeployment: true,
		enableExecuteCommand: true,
		networkConfiguration: {
			assignPublicIp: true,
			securityGroups: this.config.securityGroupIds,
			subnets: this.config.subnetIds,
		},
		tags: {
			cost: "Moderate",
		},
	});

}

export module ValheimEcsTask {
	export interface Config {
		memoryFactor: number;
		ssmPolicyArn: string;
		loggingPolicyArn: string;
		secretPolicyArn: string;
		execPolicyArn: string;
		storagePolicyArn: string;
		cpuFactor: number,
		securityGroupIds: string[],
		clusterId: string,
		subnetIds: string[],
		taskRoleArn: string,
		taskEnabled: boolean,
	}
}

export default ValheimEcsTask
