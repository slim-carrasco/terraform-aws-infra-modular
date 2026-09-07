##prueba workflow plan y apply con ruta infra/tfplan

module "security" {
  source         = "./modules/security"
  vpc_id         = module.networking.vpc_id
  bastion_enable = var.bastion_enable
  bastion_ports  = var.bastion_ports
  web_ports      = var.web_ports
  environment    = var.environment
}

module "networking" {
  source         = "./modules/networking"
  subnets_config = var.subnets_config
}

module "compute" {
  source     = "./modules/compute"
  subnets_id = module.networking.subnets_id

  instance_profile_name = module.iam.instance_profile_name
  sg_id                 = module.security.sg_id
  key_name              = var.key_name
  bastion_enable        = var.bastion_enable
}


module "iam" {
  source = "./modules/iam"
}
module "monitoring" {
  source       = "./modules/monitoring"
  instance_id  = module.compute.instance_id
  alert_emails = var.alert_emails
}
