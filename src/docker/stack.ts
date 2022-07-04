import { App, LocalBackend } from 'cdktf';
import { DockerProvider } from 'provider/docker';
import { EnhancedTerraformStack } from 'lib/EnhancedTerraformStack';

export default class Stack extends EnhancedTerraformStack {
	readonly backend: LocalBackend
	readonly providers: {
		readonly docker: DockerProvider
	}
	constructor(app: App) {
		super(app, 'docker');

		this.backend = new LocalBackend(this, {
		})

		const dockerProvider = new DockerProvider(this, 'docker', {
		})

		this.providers = {
			docker: dockerProvider
		}

	}

}
