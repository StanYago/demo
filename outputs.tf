#output "ip" {
#    value = "${aws_eip.ip.public_ip}"
#}
#output "public_ip" {
#  value = ["${aws_instance.example.*.public_ip}"]
#}
output "elb_dns_name" {
  value = "${aws_elb.web.dns_name}"
}

output "servers" {
  value = ["${aws_instance.server.*.public_ip}"]
}
output "clients" {
  value = ["${aws_instance.client.*.public_ip}"]
}
