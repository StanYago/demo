provider "aws" {
  region  = "${var.region}"
  profile = "api"
}
#Fetch latest amazon linux ami id
data "aws_ami" "linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-2017.*-x86_64-gp2"]
  }
}

#Fetch a list of Availability Zones 
data "aws_availability_zones" "available" {}

resource "aws_launch_configuration" "simpleweb_conf" {
  name_prefix   = "${var.namespace}-web-"
  image_id      = "${data.aws_ami.linux_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "tf-key"
  lifecycle {
    create_before_destroy = true
  }
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  #user_data     = "${file("${path.module}/user-data.sh")};${data.template_file.client.rendered}"
  #user_data     = "${format("%s;%s", file("${path.module}/templates/user-data.sh"), data.template_file.client.rendered)}"

  user_data = "${data.template_file.client.rendered}" 
  provisioner "local-exec" {
    command = "echo ${aws_launch_configuration.simpleweb_conf.user_data} > user_data.txt"
  }
}


resource "aws_key_pair" "tf-key" {
  key_name   = "tf-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_autoscaling_group" "web" {
  name                 = "terraform-asg-web"
  launch_configuration = "${aws_launch_configuration.simpleweb_conf.name}"
#  desired_capacity     = 3
  min_size             = 2
  max_size             = 5
  availability_zones   = ["${data.aws_availability_zones.available.names}"]

  load_balancers    = ["${aws_elb.web.name}"]
  health_check_type = "ELB"
  tag {
    key                 = "${var.consul_join_tag_key}"
    value               = "${var.consul_join_tag_value}"
    propagate_at_launch = true
  }
}

resource "aws_elb" "web" {
  name               = "terraform-asg-web"
  availability_zones = ["${data.aws_availability_zones.available.names}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }
}

resource "aws_security_group" "sg_elb" {
  name = "terraform-sg-elb"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




