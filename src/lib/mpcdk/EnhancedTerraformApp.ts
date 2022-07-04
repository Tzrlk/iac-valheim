import { App } from 'cdktf';
import EnhancedTerraformStack from 'lib/mpcdk/EnhancedTerraformStack';


export class EnhancedTerraformApp extends App {

	/** Finds all immediate children that happen to be EnhancedTerraformStacks **/
	get stacks() {
		return this.node.children
				.filter((child) => child instanceof EnhancedTerraformStack)
				.map((child) => child as EnhancedTerraformStack)
	}

}
