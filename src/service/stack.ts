import { App, LocalBackend } from 'cdktf';
import { AwsProvider } from 'provider/aws';
import { DockerProvider } from 'provider/docker';
import { HttpProvider } from 'provider/http';
import EnhancedTerraformStack from 'lib/mpcdk/EnhancedTerraformStack';
import ValheimFargateCluster from './ecs-cluster';
import ValheimServiceNetwork from './network';
import ValheimServiceStorage from './s3-storage';

export default class Stack extends EnhancedTerraformStack {
	constructor(app: App) {
		super(app, 'service');
	}

	readonly backend = new LocalBackend(this, {})

	readonly providers = {

		aws: new AwsProvider(this, 'Aws', {
			region: 'ap-southeast-2',
			defaultTags: {
				tags: {
					App: 'Valheim',
					Stack: 'Service',
				},
			}
		}),

		docker: new DockerProvider(this, 'Docker', {
			host: "tcp://localhost:2375",
		}),

		http: new HttpProvider(this, 'Http', {}),

	}

	readonly storage = new ValheimServiceStorage(this)
	readonly cluster = new ValheimFargateCluster(this, { spot: true })
	readonly network = new ValheimServiceNetwork(this)

}
