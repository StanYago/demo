variable "region" {
  default = "us-west-2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "server_port" {
  description = "The port where web server accepts connections"
  default     = 8888
}

variable "consul_join_tag_key" {
  description = "The key of the tag to auto-jon on EC2."
  default     = "consul_join"
}

variable "consul_join_tag_value" {
  description = "The value of the tag to auto-join on EC2."
  default     = "demo"
}

variable "consul_version" {
  description = "The version of Consul to install (server and client)."
  default     = "0.8.0"
}

variable "namespace" {
  description = "Unique Name"
  default     = "consuldemo"
}

variable "consul-servers" {
  description = "Number of consul servers, should be 3 or 5"
  default     = 3
}

variable "consul-clients" {
  description = "Number of consul clients"
  default     = 0
}
