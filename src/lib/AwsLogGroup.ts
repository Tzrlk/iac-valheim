import { Construct } from 'constructs';
import { CloudwatchLogGroup, CloudwatchLogGroupConfig } from 'provider/aws/cloudwatch';
import { DataAwsIamPolicyDocument, IamPolicy } from 'provider/aws/iam';


export default class AwsLogGroup extends Construct {
	readonly logGroup: CloudwatchLogGroup
	readonly accessPolicyDoc: DataAwsIamPolicyDocument
	readonly accessPolicy: IamPolicy

	constructor(scope: Construct, id: string, config: AwsLogGroup.Config) {
		super(scope, id);

		this.logGroup = new CloudwatchLogGroup(this, 'Logs', {
			namePrefix:      `${config.name}-`,
			retentionInDays: 1,
			tags: {
				cost: 'Unknown',
			},
		});

		this.accessPolicyDoc = new DataAwsIamPolicyDocument(this, 'PolicyDoc', {
			statement: [{
				sid:       'GroupActions',
				resources: [ this.logGroup.arn ],
				actions:   [
					"logs:DescribeLogGroups",
				],
			}, {
				sid:       'StreamActions',
				resources: [ `${this.logGroup.arn}:*` ],
				actions:   [
					"logs:CreateLogStream",
					"logs:DescribeLogStreams",
					"logs:PutLogEvents",
				],
			}],
		})

		this.accessPolicy = new IamPolicy(this, "ValheimLogs", {
			namePrefix: `${config.name}-`,
			policy: this.accessPolicyDoc.json,
		});

	}
}
export module AwsLogGroup {
	export interface Config {
		name:            string
		description?:    string
		logGroupConfig?: Partial<CloudwatchLogGroupConfig>

	}
}
