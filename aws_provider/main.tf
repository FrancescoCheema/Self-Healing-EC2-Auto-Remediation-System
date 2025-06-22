resource "aws_lb_target_group" "hashicups" {
  name     = "auto-scaling-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_launch_template" "self-healing" {
  name_prefix     = "testing-remediation"
  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.self-healing_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

# SNS topic to send emails with the Alerts
resource "aws_sns_topic" "alarm" {
  name              = "my-alarm-topic"
  kms_master_key_id = aws_kms_key.sns_encryption_key.id
  delivery_policy   = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
  ## This local exec, suscribes your email to the topic 
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alert_email} --region ${var.region}"
  }
}


## KMS Key to encrypt the SNS topic (security best practises)
resource "aws_kms_key" "sns_encryption_key" {
  description             = "alarms sns topic encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_cloudwatch_metric_alarm" "foobar" {
  alarm_name                = "ec2-selfremediation-monitor"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors EC2 CPU utilization"
  insufficient_data_actions = []
  alarm_actions             = [aws_lambda_function.ec2_remediator.arn, aws_sns_topic.alarm.arn]
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_self_healing_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ec2" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_lambda_function" "ec2_remediator" {
  function_name = "ec2-remediator"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  filename      = "lambda/lambda.zip"
  source_code_hash = filebase64sha256("lambda/lambda.zip")
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_remediator.function_name
  principal     = "cloudwatch.amazonaws.com"
}


