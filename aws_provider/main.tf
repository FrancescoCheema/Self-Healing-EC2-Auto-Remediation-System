resource "aws_lb_target_group" "hashicups" {
  name     = "auto-scaling-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_launch_configuration" "self-healing" {
  name_prefix     = "testing-remediation"
  image_id        = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.self-healing_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "self-healing" {
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.self-healing.name
  vpc_zone_identifier  = module.vpc.public_subnets
}