resource "aws_security_group" "projectSG_load_balancer" {
        name = "projectSG_load_balancer"
        description = "Allows a http, https"
        vpc_id = aws_vpc.project_vpc.id
        ingress {
                description = "http"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                description = "https"
                from_port = 443
                to_port = 443
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                description = "outbound access"
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
}
resource "aws_security_group" "projectSG_instance" {
        name = "projectSG_instance"
        description = "Allows a http and https access for load balancer access"
        vpc_id = aws_vpc.project_vpc.id
        ingress {
                description = "http"
                from_port = 80
                to_port = 80
                protocol = "tcp"
                security_groups = [aws_security_group.projectSG_load_balancer.id]
        }
        ingress {
                description = "https"
                from_port = 443
                to_port = 443
                protocol = "tcp"
                security_groups = [aws_security_group.projectSG_load_balancer.id]
        }
        ingress {
                description = "ssh"
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                description = "outbound access"
                from_port = 0
                to_port = 0
                protocol = "-1"
                cidr_blocks = ["0.0.0.0/0"]
        }
}

resource "aws_security_group" "projectSG_RDS" {
        name = "projectSG_RDS"
        description = "Allows a MYSQL access to instance SG"
        vpc_id = aws_vpc.project_vpc.id
        ingress {
                description = "MYSQL"
                from_port = 3306
                to_port = 3306
                protocol = "tcp"
                security_groups = [aws_security_group.projectSG_instance.id]
        }
}

resource "aws_launch_template" "projectLT" {
        name = "projectLT"
        instance_type = "t2.micro"
        image_id = "ami-0c7217cdde317cfec"
        user_data = filebase64("${path.module}/user_data.sh")
        vpc_security_group_ids = [aws_security_group.projectSG_instance.id]
        key_name = "local"
	iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
        block_device_mappings {
            device_name = "/dev/sdf"
                ebs {
                    volume_type = "gp3"
                    volume_size = 8
                }
        }
}

resource "aws_autoscaling_group" "projectASG" {
        name = "projectASG"
        vpc_zone_identifier  = [for subnet in aws_subnet.private_subnet : subnet.id]
        desired_capacity = 3
        max_size = 5
        min_size = 1

        launch_template {
            id = aws_launch_template.projectLT.id
            version = "$Latest"
        }
}
resource "aws_lb" "projectLB" {
        name = "projectLB"
        internal = false
        load_balancer_type = "application"
        security_groups = [aws_security_group.projectSG_load_balancer.id]
        subnets = [for subnet in aws_subnet.private_subnet : subnet.id]
}

resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.project_vpc.id
}
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.projectLB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}
