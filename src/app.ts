import { EnhancedTerraformApp } from 'lib/mpcdk/EnhancedTerraformApp';

import ValheimDockerStack from 'docker/stack'
import ValheimServiceStack from 'service/stack'

export default class App extends EnhancedTerraformApp {
	readonly docker: ValheimDockerStack
	readonly service: ValheimServiceStack

	constructor() {
		super();

		this.docker = new ValheimDockerStack(this)

		this.service = new ValheimServiceStack(this)

	}
}
