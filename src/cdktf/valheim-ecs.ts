import { Construct } from 'constructs';
import { App, TerraformStack } from 'cdktf';
import {
	DataAwsRegion,
	AwsProvider,
} from '@cdktf/provider-aws';

export function buildValheimEcs(app: App): TerraformStack {
	return new TerraformStack(app, 'valheim-ecs').also((stack) => {
		
	})
}

export class ValheimEcs extends TerraformStack {
	constructor(scope: Construct) {
		super(scope, 'valheim-ecs');

		new AwsProvider(this, 'aws', {
			region: 'ap-southeast-2',
		});

		new DataAwsRegion(this, 'region');

	}
}