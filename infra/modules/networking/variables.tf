variable "subnets_config" {
  type = map(object({
    cidr_block        = string
    is_public         = bool
    availability_zone = string
    
  }))
}
