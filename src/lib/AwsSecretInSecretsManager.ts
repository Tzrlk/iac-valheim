import { Construct } from 'constructs';
import { LazyGetter } from 'lazy-get-decorator';
import { AwsSecret } from 'lib/AwsSecret';
import { DataAwsIamPolicyDocument } from 'provider/aws/iam';
import { SecretsmanagerSecret, SecretsmanagerSecretVersion } from 'provider/aws/secretsmanager';

export class AwsSecretInSecretsManager extends AwsSecret<AwsSecretInSecretsManager.Config> {

	constructor(scope: Construct, id: string, config: AwsSecretInSecretsManager.Config) {
		super(scope, id, config);
	}

	@LazyGetter()
	get secret() {
		return new SecretsmanagerSecret(this, 'Secret', {
			namePrefix: `${this.config.name}-`,
			description: this.config.description,
		})
	}

	@LazyGetter()
	get version() {
		return new SecretsmanagerSecretVersion(this, 'Value', {
			secretId: this.secret.id,
			secretString: this.config.binary ? undefined : this.config.secret(),
			secretBinary: this.config.binary ? this.config.secret() : undefined,

		}).also((version) => {
			version.addOverride('lifecycle', {
				ignore_changes: [ 'version_stages' ],
			})
		})
	}

	@LazyGetter()
	get accessPolicyDoc() {
		return new DataAwsIamPolicyDocument(this, "ServerPassAccess", {
			statement: [{
				resources: [ this.secret.arn ],
				actions:   [
					"secretsmanager:GetSecretValue",
				],
			}],
		});
	}

}

export module AwsSecretInSecretsManager {
	export interface Config extends AwsSecret.Config {
		readonly binary?: boolean
	}
}
