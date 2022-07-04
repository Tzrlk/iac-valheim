import { Construct } from 'constructs';
import { EcsCluster, EcsClusterCapacityProviders } from 'provider/aws/ecs';
import 'scope-extensions-js'
import { DataAwsIamPolicy, DataAwsIamPolicyDocument, IamPolicy } from 'provider/aws/iam';

export default class ValheimFargateCluster extends Construct {

	constructor(scope: Construct, private readonly config: ValheimFargateCluster.Config) {
		super(scope, 'EcsCluster');

	}

	readonly cluster = new EcsCluster(this, "Valheim", {
		name: "valheim",
		tags: {
			cost: "Free",
		},
	});

	readonly clusterCapacity = new EcsClusterCapacityProviders(this, "FargateSpot", {
		capacityProviders: [ this.config.spot ? "FARGATE_SPOT" : "FARGATE" ],
		clusterName:       this.cluster.name,
	});

	readonly taskExecPolicy = new DataAwsIamPolicy(this, "AmazonECSTaskExecutionRolePolicy", {
		arn: "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
	});

	readonly ecsTrustPolicyDoc = new DataAwsIamPolicyDocument(this, "EcsTrust", {
		statement: [{
			actions:    [ "sts:AssumeRole" ],
			principals: [{
				identifiers: [ "ecs-tasks.amazonaws.com" ],
				type:        "Service",
			}],
		}],
	});

	readonly ssmAccessPolicyDoc = new DataAwsIamPolicyDocument(this, "SsmAccess", {
		statement: [{
			resources: [ "*" ],
			actions:   [
				"ssmmessages:CreateControlChannel",
				"ssmmessages:CreateDataChannel",
				"ssmmessages:OpenControlChannel",
				"ssmmessages:OpenDataChannel",
			],
		}],
	});


	// readonly taskExecPolicy = new IamPolicy(this, "ECSTaskExecutionRolePolicy", {
	// 	policy: this.taskExecPolicy.policy,
	// 	tags: {
	// 		cost: "Free",
	// 	},
	// });

	readonly ssmAccessPolicy = new IamPolicy(this, "SsmAccess_29", {
		namePrefix: "ssm-access-",
		policy: this.ssmAccessPolicyDoc.json,
	});


}

module ValheimFargateCluster {
	export type Config = {
		spot: boolean
	}
}
