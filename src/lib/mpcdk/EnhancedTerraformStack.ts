import 'scope-extensions-js'
import {
	App,
	TerraformElement,
	TerraformStack,
} from 'cdktf';
import {
	IConstruct,
	Node,
} from 'constructs'

type Constructor<T> = { new(...args: any[]): T }

export default abstract class EnhancedTerraformStack extends TerraformStack {

	protected constructor(app: App, id: string) {
		super(app, id);
	}

	/**
	 * Overriding this functionality to avoid creating massive ids.
	 * @param item The item to generate an id for.
	 * @protected
	 */
	protected allocateLogicalId(item: Node | TerraformElement): string {
		if (item instanceof TerraformElement) {
			return this.allocateLogicalId(item.node)
		}

		// Recursively search for the stack?
		// Just implement whatever dumb shit it was doing.
		const stackIndex = item.scopes.findIndex((construct) => construct instanceof TerraformStack)
		return item.scopes.slice(stackIndex + 1)
				.map(construct => construct.node.id)
				.join('')
	}

	findOne<T extends IConstruct>(type: Constructor<T>, id?: string): T | undefined {
		return this.node.children
				.find((child) =>
						child instanceof type && (
								id == undefined ||
								id == child.node.id))
				?.let((child) => child as T)
	}

}
