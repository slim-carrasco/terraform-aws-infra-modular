variable "vpc_id" {
  type = string
}

variable "bastion_enable" {
  type = bool
}
variable "bastion_ports" {
  type = map(number)
}
variable "web_ports" {
  type = map(number)
}
variable "environment" {
  type = string
  default = "produccion"
}

