import { TerraformStack, TerraformVariable  } from "cdktf";


export function aws_secret(stack: TerraformStack, id: string, name: string, desc: string) {

	new TerraformVariable(stack, id, {
		description: desc,
		type: 'string',
		nullable: false,
	})
	
	new AwsSecretsmanagerSecret()

}