variable "sg_id" {
  type = string
}

variable "subnets_id" {
  type = map(string)
}

variable "key_name" {
  

type=string
}

variable "instance_profile_name" {
  type = string
}

variable "bastion_enable" {
  type = bool
}
