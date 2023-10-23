provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "${var.region}b"
}

resource "aws_internet_gateway" "my-inet-gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.main.id

  ### I'm fully aware that I can set more specific routes than the default one,
  ### avoiding it to use the local route. But I'm not sure what to use in this 
  ### particular case instead. So I'm not including those routes.

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-inet-gw.id
  }
}

resource "aws_autoscaling_group" "my-autoscaling-group" {
  availability_zones = ["${var.region}a", "${var.region}b"]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2

  launch_template {
    id      = aws_launch_template.my-launch-template.id
    version = "$Latest"
  }

  default_cooldown          = var.cooldown
  health_check_grace_period = var.healthcheck_grace_period
  health_check_type         = "ELB"
}

resource "aws_launch_template" "my-launch-template" {
  name_prefix   = "foobar"
  image_id      = "ami-0df435f331839b2d6" #Amazon Linux
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "my-target-group" {
  name     = "example"
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  deregistration_delay = var.deregistration_delay

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }
}

resource "aws_lb" "my-alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_lb_listener" "my-listener" {
  load_balancer_arn = aws_lb.my-alb.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-target-group.arn
  }
}
