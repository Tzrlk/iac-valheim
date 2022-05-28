# Expose a record that will point to the server instances

resource "aws_route53_zone" "Aetheric" {
	name = "aetheric.co.nz"
	tags = {
		Cost = "Cheap"
	}
}

data "aws_iam_policy_document" "ZoneRecordControl" {
	statement {
		resources = [ aws_route53_zone.Aetheric.arn ]
		actions   = [
			"route53:ListHostedZones",
			"route53:GetHostedZone",
			"route53:ListResourceRecordSets",
			"route53:ChangeResourceRecordSets",
		]
	}
}
resource "aws_iam_policy" "ZoneRecordControl" {
	policy = data.aws_iam_policy_document.ZoneRecordControl.json
	tags = {
		Cost = "Free"
	}
}
