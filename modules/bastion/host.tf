resource "tls_private_key" "bastion-private-key" {
  algorithm = "RSA"
}

resource "aws_secretsmanager_secret" "bastion-key" {
  name = "/${var.environment}/credentials/bastion_key"
}

resource "aws_secretsmanager_secret_version" "bastion-key-version" {
  secret_id     = aws_secretsmanager_secret.bastion-key.id
  secret_string = tls_private_key.bastion-private-key.private_key_pem
}

resource "aws_instance" "bastion-instance" {
  ami           = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"

  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = "${var.project}-${var.environment}-bastion"

  iam_instance_profile = aws_iam_instance_profile.bastion_instance_profile.name

  vpc_security_group_ids = [
    aws_security_group.security-group-bastion.id
  ]

  tags = {
    Name      = "${var.project}-${var.environment}-bastion"
    ManagedBy = "${var.project}-tf"
  }
}

resource "aws_security_group" "security-group-bastion" {
  name        = "${var.project}-${var.environment}-security-group-bastion"
  description = "Allows access to ${var.environment} bastion host"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    security_groups = [aws_security_group.nlb_main_security_group.id]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "bastion-${var.environment}-ec2-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
EOF
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "bastion-${var.environment}-instance-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role_policy" "bastion_resource_access_policy" {
  name   = "bastion-${var.environment}-resource-access"
  role   = aws_iam_role.bastion_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action":     [
                "s3:ListAccessPointsForObjectLambda",
                "s3:GetObjectVersionTagging",
                "s3:GetStorageLensConfigurationTagging",
                "s3:GetObjectAcl",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetIntelligentTieringConfiguration",
                "s3:GetObjectVersionAcl",
                "s3:GetBucketPolicyStatus",
                "s3:GetObjectRetention",
                "s3:GetBucketWebsite",
                "s3:GetJobTagging",
                "s3:ListJobs",
                "s3:GetMultiRegionAccessPoint",
                "s3:GetObjectAttributes",
                "s3:GetObjectLegalHold",
                "s3:GetBucketNotification",
                "s3:DescribeMultiRegionAccessPointOperation",
                "s3:GetReplicationConfiguration",
                "s3:ListMultipartUploadParts",
                "s3:GetObject",
                "s3:DescribeJob",
                "s3:GetAnalyticsConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetAccessPointForObjectLambda",
                "s3:GetStorageLensDashboard",
                "s3:GetLifecycleConfiguration",
                "s3:GetAccessPoint",
                "s3:GetInventoryConfiguration",
                "s3:GetBucketTagging",
                "s3:GetAccessPointPolicyForObjectLambda",
                "s3:GetBucketLogging",
                "s3:ListBucketVersions",
                "s3:ListBucket",
                "s3:GetAccelerateConfiguration",
                "s3:GetObjectVersionAttributes",
                "s3:GetBucketPolicy",
                "s3:GetEncryptionConfiguration",
                "s3:GetObjectVersionTorrent",
                "s3:GetBucketRequestPayment",
                "s3:GetAccessPointPolicyStatus",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "s3:GetBucketOwnershipControls",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetMultiRegionAccessPointPolicyStatus",
                "s3:ListBucketMultipartUploads",
                "s3:GetMultiRegionAccessPointPolicy",
                "s3:GetAccessPointPolicyStatusForObjectLambda",
                "s3:ListAccessPoints",
                "s3:GetBucketVersioning",
                "s3:ListMultiRegionAccessPoints",
                "s3:GetBucketAcl",
                "s3:GetAccessPointConfigurationForObjectLambda",
                "s3:ListStorageLensConfigurations",
                "s3:GetObjectTorrent",
                "s3:GetMultiRegionAccessPointRoutes",
                "s3:GetStorageLensConfiguration",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:GetBucketCORS",
                "s3:GetBucketLocation",
                "s3:GetAccessPointPolicy",
                "s3:GetObjectVersion"
            ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
}
EOF
}