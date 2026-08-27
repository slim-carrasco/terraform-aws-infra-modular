


variable "alert_emails" {
  type = list(string)


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
  default = "prod"
}

variable "subnets_config" {
  type = map(object({
    cidr_block        = string
    is_public         = bool
    availability_zone = string

  }))
}









variable "key_name" {


type=string
}
