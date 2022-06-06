import { TerraformVariable } from "cdktf";
import { Construct } from 'constructs';
import { SecretsmanagerSecret, SecretsmanagerSecretVersion } from '../../.gen/providers/aws/secretsmanager';

export function aws_secret(stack: Construct, id: string, name: string, desc: string) {

	const input = new TerraformVariable(stack, id, {
		description: desc,
		type: 'string',
		nullable: false,
		sensitive: true,
	})

	const secret = new SecretsmanagerSecret(stack, id, {
		description: desc,
		namePrefix: `${name}-`,
	})

	new SecretsmanagerSecretVersion(stack, id, {
		secretId: secret.id,
		secretString: input.stringValue,
	})

}
