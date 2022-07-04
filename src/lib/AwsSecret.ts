import { Construct } from 'constructs';
import { LazyGetter } from 'lazy-get-decorator';
import { DataAwsIamPolicyDocument, IamPolicy } from 'provider/aws/iam';

export abstract class AwsSecret<Config extends AwsSecret.Config> extends Construct {

	protected constructor(scope: Construct, id: string, protected readonly config: Config) {
		super(scope, id);
	}

	abstract get accessPolicyDoc(): DataAwsIamPolicyDocument

	@LazyGetter()
	get secretAccess(): IamPolicy {
		return new IamPolicy(this, "SecretAccess", {
			name:  `${this.config.name}-secrets-access`,
			policy: this.accessPolicyDoc.json,
			tags: {
				cost: "Free",
			},
		});
	}

}
export module AwsSecret {
	export interface Config {
		readonly name: string
		readonly description?: string
		readonly secret: () => string
	}
}
