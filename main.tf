module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  app_port     = var.app_port
}

module "compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  ecs_sg_id          = module.security.ecs_sg_id
  container_image    = var.container_image
  app_port           = var.app_port
  db_host            = module.database.db_address
  db_port            = module.database.db_port
  db_name            = module.database.db_name
  db_secret_arn      = module.database.db_secret_arn
}

module "database" {
  source = "./modules/database"

  project_name  = var.project_name
  vpc_id        = module.networking.vpc_id
  db_subnet_ids = module.networking.db_subnet_ids
  db_sg_id      = module.security.db_sg_id
}

module "cicd" {
  source = "./modules/cicd"

  project_name            = var.project_name
  github_repository       = var.github_repository
  task_execution_role_arn = module.compute.task_execution_role_arn
}
