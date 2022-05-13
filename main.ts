import { Construct } from 'constructs';
import { App, TerraformStack } from 'cdktf';
import {
	DataAwsRegion,
	AwsProvider,
} from '@cdktf/provider-aws';

export class IacValheim extends TerraformStack {
	constructor(scope: Construct, stackId: string) {
		super(scope, stackId);

		new AwsProvider(this, 'aws', {
			region: 'ap-southeast-2',
		});

		new DataAwsRegion(this, 'region');
		
	}
}

const app = new App();
new IacValheim(app, 'iac-valheim');
app.synth();