provider "aws" {
  profile = "default"
  region  = "sa-east-1"
}
resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.defaultvpc

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = [for net in var.subnet : net]
}
resource "aws_instance" "server" {
  ami                    = var.linux_image
  instance_type          = var.istance_type
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
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


resource "aws_lb_target_group" "targetgptest" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.defaultvpc
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.targetgptest.arn
  target_id        = aws_instance.server.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "test2" {
  target_group_arn = aws_lb_target_group.targetgptest.arn
  target_id        = aws_instance.server2.id
  port             = 80
}
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetgptest.arn
  }
}



