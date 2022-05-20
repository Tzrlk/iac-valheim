import { App, TerraformStack } from 'cdktf';
import {
	DataAwsRegion,
	AwsProvider,
} from '@cdktf/provider-aws';

export class ValheimEcs extends TerraformStack {
	constructor(scope: App) {
		super(scope, 'valheim-ecs');

		new AwsProvider(this, 'aws', {
			region: 'ap-southeast-2',
		});

		new DataAwsRegion(this, 'region');

	}
}