import { Construct } from 'constructs';
import AwsLogGroup from 'lib/AwsLogGroup';
import { DataAwsIamPolicyDocument, IamPolicy, IamRole } from 'provider/aws/iam';
import { FlowLog, Vpc } from 'provider/aws/vpc';


export default class ValheimServiceMonitoring extends Construct {
	constructor(scope: Construct) {
		super(scope, 'Monitoring');

		const vpc = scope.node.root.node.findChild('Vpc') as Vpc

		return
		const awsFlowLogVpcFlowLogs = new FlowLog(this, "VpcFlowLogs", {
			iamRoleArn: this.flowLogsRole.arn,
			logDestination: this.flowLogs.logGroup.arn,
			maxAggregationInterval: 60,
			trafficType: "ALL",
			vpcId: vpc.id,
		});

	}

	readonly valheimLogs = new AwsLogGroup(this, "ValheimLogs", {
		name: "valheim-server",
	});

	readonly flowLogs = new AwsLogGroup(this, "FlowLogs", {
		name: "valheim-flow-logs",
	})

	readonly flowLogsTrustPolicyDoc = new DataAwsIamPolicyDocument(this, "VpcFlowLogsTrust", {
		statement: [{
			actions:    [ "sts:AssumeRole" ],
			principals: [{
				type:        "Service",
				identifiers: [ "vpc-flow-logs.amazonaws.com" ],
			}],
		}],
	});
	readonly flowLogsRole = new IamRole(this, "VpcFlowLogs", {
		namePrefix: "valheim-flow-logs-",
		assumeRolePolicy: this.flowLogsTrustPolicyDoc.json,
		managedPolicyArns: [
			this.flowLogs.accessPolicy.arn,
		]
	});

}
