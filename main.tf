data "aws_subnets" "targetSubnets" {
  filter {
    name   = "tag:Name"
    values = ["minimal-server-subnet-us-e-*"]
  }
}



resource "aws_instance" "minimal-server-1" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t2.nano"
  user_data_base64       = "IyEvYmluL2Jhc2gKYXB0LWdldCB1cGRhdGUgLXkKYXB0LWdldCBpbnN0YWxsIC15IFwKICBjYS1jZXJ0aWZpY2F0ZXMgXAogIGN1cmwgXAogIGdudXBnIFwKICBsc2ItcmVsZWFzZSBcCiAgdW56aXAKCnN1ZG8gYXB0IGluc3RhbGwgLXkgZG9ja2VyLmlvCgpzdWRvIGFkZHVzZXIgZG9ja2VydXNlcgpzdWRvIHVzZXJtb2QgLWFHIGRvY2tlciBkb2NrZXJ1c2VyCgpjdXJsICJodHRwczovL2F3c2NsaS5hbWF6b25hd3MuY29tL2F3c2NsaS1leGUtbGludXgteDg2XzY0LnppcCIgLW8gImF3c2NsaXYyLnppcCIKdW56aXAgYXdzY2xpdjIuemlwCnN1ZG8gLi9hd3MvaW5zdGFsbAoKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIGRvY2tlcgpzdWRvIHN5c3RlbWN0bCBzdGFydCBkb2NrZXIKCnN1ZG8gc3lzdGVtY3RsIGVuYWJsZSBzbmFwLmFtYXpvbi1zc20tYWdlbnQuYW1hem9uLXNzbS1hZ2VudC5zZXJ2aWNlCnN1ZG8gc3lzdGVtY3RsIHN0YXJ0IHNuYXAuYW1hem9uLXNzbS1hZ2VudC5hbWF6b24tc3NtLWFnZW50LnNlcnZpY2U="
  iam_instance_profile   = "ecsInstanceRole"
  vpc_security_group_ids = ["sg-01d2d407c794f046b"]
  subnet_id              = "subnet-0796156a31ad3cdad"
  tags = {
    Name = "minimal-server-1",
    current_status = "Blue"
  }
}

resource "aws_instance" "minimal-server-2" {
  ami                    = "ami-0ecb62995f68bb549"
  instance_type          = "t2.nano"
  user_data_base64       = "IyEvYmluL2Jhc2gKYXB0LWdldCB1cGRhdGUgLXkKYXB0LWdldCBpbnN0YWxsIC15IFwKICBjYS1jZXJ0aWZpY2F0ZXMgXAogIGN1cmwgXAogIGdudXBnIFwKICBsc2ItcmVsZWFzZSBcCiAgdW56aXAKCnN1ZG8gYXB0IGluc3RhbGwgLXkgZG9ja2VyLmlvCgpzdWRvIGFkZHVzZXIgZG9ja2VydXNlcgpzdWRvIHVzZXJtb2QgLWFHIGRvY2tlciBkb2NrZXJ1c2VyCgpjdXJsICJodHRwczovL2F3c2NsaS5hbWF6b25hd3MuY29tL2F3c2NsaS1leGUtbGludXgteDg2XzY0LnppcCIgLW8gImF3c2NsaXYyLnppcCIKdW56aXAgYXdzY2xpdjIuemlwCnN1ZG8gLi9hd3MvaW5zdGFsbAoKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIGRvY2tlcgpzdWRvIHN5c3RlbWN0bCBzdGFydCBkb2NrZXIKCnN1ZG8gc3lzdGVtY3RsIGVuYWJsZSBzbmFwLmFtYXpvbi1zc20tYWdlbnQuYW1hem9uLXNzbS1hZ2VudC5zZXJ2aWNlCnN1ZG8gc3lzdGVtY3RsIHN0YXJ0IHNuYXAuYW1hem9uLXNzbS1hZ2VudC5hbWF6b24tc3NtLWFnZW50LnNlcnZpY2U="
  iam_instance_profile   = "ecsInstanceRole"
  vpc_security_group_ids = ["sg-01d2d407c794f046b"]
  subnet_id              = "subnet-0eb8be0e70ab37cab"
  tags = {
    Name = "minimal-server-2",
    current_status = "Green"
  }
}

resource "aws_alb_target_group" "minimal-server-1-tg" {
  name        = "minimal-server-1-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0821b6561ddec5894"
  target_type = "instance"
  health_check {
    path                = "/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

}

resource "aws_lb_target_group_attachment" "minimal-server-1-attachment" {
  target_group_arn = aws_alb_target_group.minimal-server-1-tg.arn
  target_id        = aws_instance.minimal-server-1.id
  port             = 80
}

resource "aws_alb_target_group" "minimal-server-2-tg" {
  name        = "minimal-server-2-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "vpc-0821b6561ddec5894"
  target_type = "instance"
  health_check {
    path                = "/status"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

}

resource "aws_lb_target_group_attachment" "minimal-server-2-attachment" {
  target_group_arn = aws_alb_target_group.minimal-server-2-tg.arn
  target_id        = aws_instance.minimal-server-2.id
  port             = 80
}




resource "aws_lb" "minimal-server-alb" {
  name                       = "minimal-server-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["sg-01d2d407c794f046b"]
  subnets                    = data.aws_subnets.targetSubnets.ids
  enable_deletion_protection = false

}

resource "aws_lb_listener" "blue-green-listner" {
  load_balancer_arn = aws_lb.minimal-server-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_alb_target_group.minimal-server-1-tg.arn
        weight = 100
      }
      target_group {
        arn    = aws_alb_target_group.minimal-server-2-tg.arn
        weight = 0
      }
    }
  }
}
