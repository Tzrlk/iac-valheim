import { App, TerraformStack, TerraformVariable } from 'cdktf';
import { IacValheimTf } from '../../.gen/modules/iac-valheim-tf';
import { AwsProvider } from '../../.gen/providers/aws';
import { DockerProvider } from '../../.gen/providers/docker';

export class ValheimEcs extends TerraformStack {
	constructor(scope: App) {
		super(scope, 'valheim-ecs');

		new AwsProvider(this, 'aws', {
			region: 'ap-southeasst-2',
			defaultTags: {
				tags: {
					App: 'Valheim',
				},
			}
		})

		new DockerProvider(this, 'docker', {})

		const adminList = new TerraformVariable(this, 'AdminList', {
			description: 'The list of Steam Ids to nominate as admins.',
			type: 'string[]',
		})

		new IacValheimTf(this, 'vhtf', {
			adminList: adminList.listValue,
			runServer: false,
			serverPass: '',
			sketchy: true,
		})

	}
}
