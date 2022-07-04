import { Construct } from 'constructs'
import { DataAwsIamPolicyDocument, IamPolicy } from 'provider/aws/iam';
import {
	S3Bucket,
	S3BucketAcl,
	S3BucketLifecycleConfiguration,
	S3BucketVersioningA,
} from 'provider/aws/s3'
import 'scope-extensions-js'

export default class Storage extends Construct {
	constructor(scope: Construct) {
		super(scope, 'Storage')
	}

	readonly bucket = new S3Bucket(this, 'Bucket', {
		bucketPrefix: 'valheim-'
	}).also(bucket => {
		bucket.overrideLogicalId('Valheim')
		bucket.addOverride('lifecycle', [{
			prevent_destroy: true,
		}])
	})

	readonly bucketAcl = new S3BucketAcl(this, 'Access', {
		bucket: this.bucket.id,
		acl:    'private',
	}).also(bucketAcl => {
		bucketAcl.overrideLogicalId('Valheim')
	})

	readonly bucketVersioning = new S3BucketVersioningA(this, 'Versioning', {
		bucket: this.bucket.id,
		versioningConfiguration: {
			status: 'Enabled',
		},
	}).also(bucketVersioning => {
		bucketVersioning.overrideLogicalId('Valheim')
	})

	readonly bucketLifecycle = new S3BucketLifecycleConfiguration(this, "Lifecycle", {
		bucket: this.bucket.id,
		rule: [{
			id: 'store',
			status: 'Enabled',
			filter: {},
			abortIncompleteMultipartUpload: {
				daysAfterInitiation: 1,
			},
			noncurrentVersionExpiration: {
				newerNoncurrentVersions: '5',
				noncurrentDays: 30,
			},
		}],
	}).also(bucketLifecycle => {
		bucketLifecycle.overrideLogicalId('Valheim');
	})

	readonly policyDoc = new DataAwsIamPolicyDocument(this, "AccessPolicyDoc", {
		statement: [{
			resources: [ this.bucket.arn ],
			actions:   [
				"s3:ListBucket",
				"s3:LocateBucket",
				"s3:DescribeBucket",
				"s3:GetBucketLocation",
				"s3:ListBucketMultipartUploads",
			],
		}, {
			resources: [ `\${${this.bucket.arn}}/*` ],
			actions:   [
				"s3:GetObject",
				"s3:PutObject",
				"s3:GetObjectAcl",
				"s3:PutObjectAcl",
				"s3:DeleteObject",
				"s3:DeleteObjectAcl",
				"s3:GetObjectTagging",
				"s3:PutObjectTagging",
				"s3:AbortMultipartUpload",
				"s3:ListMultipartUploadParts",
			],
		}],
	})

	readonly accessPolicy = new IamPolicy(this, "AccessPolicy", {
		policy: this.policyDoc.json,
	}).also(accessPolicy => {
		accessPolicy.overrideLogicalId("ValheimS3");
	})

}
