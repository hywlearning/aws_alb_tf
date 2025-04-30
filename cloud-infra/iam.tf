# Step 1: Create IAM Role that EC2 can Assume
resource "aws_iam_role" "admin-role" {
  name               = "admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Step 2: Attach AdministratorAccess Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "admin-policy-attachment" {
  role       = aws_iam_role.admin-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Step 3: Create an IAM Instance Profile for EC2 to use the Role
resource "aws_iam_instance_profile" "admin-instance-profile" {
  name = "admin-instance-profile"
  role = aws_iam_role.admin-role.name
}

resource "aws_s3_bucket_policy" "alb_logging_policy" {
  bucket = aws_s3_bucket.s3_alb.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AWSLogDeliveryWrite",
        Effect: "Allow",
        Principal: {
          Service: "logdelivery.elb.amazonaws.com"
        },
        Action: "s3:PutObject",
        Resource: "${aws_s3_bucket.s3_alb.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Sid: "AWSLogDeliveryAclCheck",
        Effect: "Allow",
        Principal: {
          Service: "logdelivery.elb.amazonaws.com"
        },
        Action: "s3:GetBucketAcl",
        Resource: aws_s3_bucket.s3_alb.arn
      }
    ]
  })

  depends_on = [aws_s3_bucket.s3_alb]
}



