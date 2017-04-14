# Create the user-data for the Consul server
data "template_file" "server" {
  count    = "${var.consul-servers}"
  template = "${file("${path.module}/templates/consul.sh.tpl")}"

  vars {
    consul_version = "${var.consul_version}"

    config = <<EOF
     "bootstrap_expect": 3,
     "node_name": "${var.namespace}-server-${count.index}",
     "retry_join_ec2": {
       "tag_key": "${var.consul_join_tag_key}",
       "tag_value": "${var.consul_join_tag_value}"
     },
     "server": true
    EOF
  }
}

# Create the user-data for the Consul client
data "template_file" "client" {
  template = "${file("${path.module}/templates/consul-client.sh.tpl")}"

  vars {
    consul_version = "${var.consul_version}"

    config = <<EOF
     "retry_join_ec2": {
       "tag_key": "${var.consul_join_tag_key}",
       "tag_value": "${var.consul_join_tag_value}"
     },
     "server": false
    EOF
  }
}

# Create Consul server cluster
resource "aws_instance" "server" {
  count = "${var.consul-servers}"
  ami           = "${data.aws_ami.linux_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "tf-key"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"
#  subnet_id              = "${element(aws_subnet.consul.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
#  vpc_security_group_ids = ["${aws_security_group.consul.id}"]
  tags = "${map(
    "Name", "${var.namespace}-server-${count.index}",
    var.consul_join_tag_key, var.consul_join_tag_value
  )}"
  user_data = "${element(data.template_file.server.*.rendered, count.index)}"
}

# Add Consul Clients
resource "aws_instance" "client" {
  count = "${var.consul-clients}"
  ami           = "${data.aws_ami.linux_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "tf-key"
#  subnet_id              = "${element(aws_subnet.consul.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
#  vpc_security_group_ids = ["${aws_security_group.consul.id}"]
  tags = "${map(
    "Name", "${var.namespace}-client-${count.index}",
    var.consul_join_tag_key, var.consul_join_tag_value
  )}"
  user_data = "${element(data.template_file.client.*.rendered, count.index)}"
}

# Create an IAM role for the auto-join
resource "aws_iam_role" "consul-join" {
  name               = "${var.namespace}-consul-join"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}
# Create the policy
resource "aws_iam_policy" "consul-join" {
  name        = "${var.namespace}-consul-join"
  description = "Allows Consul nodes to describe instances for joining."
  policy      = "${file("${path.module}/templates/policies/describe-instances.json")}"
}


# Attach the policy
resource "aws_iam_policy_attachment" "consul-join" {
  name       = "${var.namespace}-consul-join"
  roles      = ["${aws_iam_role.consul-join.name}"]
  policy_arn = "${aws_iam_policy.consul-join.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "consul-join" {
  name  = "${var.namespace}-consul-join"
  role = "${aws_iam_role.consul-join.name}"
}

