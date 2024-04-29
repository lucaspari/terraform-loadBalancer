provider "aws" {
  profile = "default"
  region  = "sa-east-1"
}
resource "aws_instance" "server" {
  ami                    = var.linux_image
  instance_type          = var.istance_type
  vpc_security_group_ids = [var.security_groups]
  user_data              = <<-EOF
                                    #!/bin/bash
                                    # Use this for your user data (script from top to bottom)
                                    # install httpd (Linux 2 version)
                                    yum update -y
                                    yum install -y httpd
                                    systemctl start httpd
                                    systemctl enable httpd
                                    echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html 
EOF
}

resource "aws_instance" "server2" {
  ami                    = var.linux_image
  instance_type          = var.istance_type
  vpc_security_group_ids = [var.security_groups]
  user_data              = <<-EOF
                                    #!/bin/bash
                                    # Use this for your user data (script from top to bottom)
                                    # install httpd (Linux 2 version)
                                    yum update -y
                                    yum install -y httpd
                                    systemctl start httpd
                                    systemctl enable httpd
                                    echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html 
EOF
}

resource "aws_lb" "demoalb" {
  name               = "demoalb"
  security_groups    = [var.security_group_http]
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  subnets            = [for id in var.subnet : id]
}
resource "aws_lb_target_group" "demoalb_target_group" {
  name     = "demoalb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.defaultvpc

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "demoalb_listener" {
  load_balancer_arn = aws_lb.demoalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demoalb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "server_attachment" {
  target_group_arn = aws_lb_target_group.demoalb_target_group.arn
  target_id        = aws_instance.server.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "server2_attachment" {
  target_group_arn = aws_lb_target_group.demoalb_target_group.arn
  target_id        = aws_instance.server2.id
  port             = 80
}



