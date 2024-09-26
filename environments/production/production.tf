# VPC
module "production_vpc" {
  source = "../../modules/vpc"
  vpc_cidr_block = "172.16.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
  name = "production-vpc"
  tags = {
    Environment = "production"
    Project     = "cloudops"
  }
}

module "production_bastion_host" {
  source      = "../../modules/bastion"
  environment = "production"
  project     = "cloudops"
  vpc_id      = module.production_vpc.vpc_id
  subnet_id   = module.production_vpc.public_subnets[0]
  public_subnets = module.production_vpc.public_subnets


  depends_on = [
    module.production_vpc
  ]

}

module "production_database" {
  source                       = "../../modules/rds"
  database_name                = "api"
  instance_type                = "db.t3.medium"
  secrets_path                 = "/production/api/database-1MP81m"
  subnets                      = module.production_vpc.private_subnets
  maintainer                   = "cloudops"
  encryption_enabled           = true
  region                       = "us-east-1"
  project                      = "api"
  environment                  = "production"
  vpc_cidr                     = module.production_vpc.vpc_cidr_block 
  vpc_id                       = module.production_vpc.vpc_id
  apply_immediately            = false
  multi_az                     = true
  backup_retention_period      = 35
  performance_insights_enabled = true
  monitoring_interval          = 60
  max_allocated_storage        = 160
  depends_on = [
    module.production_vpc
  ]
}

module "production_redis" {
  source                     = "../../modules/redis"
  environment                = "production"
  project                    = "cloudops"
  name_prefix                = "redis"
  number_cache_clusters      = 2
  node_type                  = "cache.t3.medium"
  cluster_mode_enabled       = false
  replicas_per_node_group    = 1
  num_node_groups            = 1
  multi_az_enabled           = true
  engine_version             = "6.x"
  port                       = 6379
  maintenance_window         = "mon:03:00-mon:04:00"
  snapshot_window            = "04:00-06:00"
  snapshot_retention_limit   = 30
  automatic_failover_enabled = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  apply_immediately          = false
  family                     = "redis6.x"
  subnet_ids                 = module.production_vpc.private_subnets
  vpc_id                     = module.production_vpc.vpc_id
  ingress_cidr_blocks        = ["0.0.0.0/0"]
}


module "production_ecs_fargate" {
  maintainer               = "tandym"
  source                   = "../../modules/ecs-fargate"
  app_domain_name          = "bytandym.com"
  project                  = "api"
  environment              = "production"
  container_port_api       = "8080"
  container_port_backend   = "9090"
  vpc_id                   = module.production_vpc.vpc_id
  vpc_cidr                 = module.production_vpc.vpc_cidr_block
  api_image                = "782993620179.dkr.ecr.us-east-1.amazonaws.com/api-production-fargate:latest"
  private_subnets          = module.production_vpc.private_subnets
  public_subnets           = module.production_vpc.public_subnets
  depends_on               = [module.production_vpc]
  region                   = "us-east-1"
  health_check_path        = "/"
  backend_secrets          = jsondecode(file("../../${path.module}/config/production/api-secrets.json"))
  environment_secrets      = jsondecode(file("../../${path.module}/config/production-secrets.json"))
  api_task_cpu             = "1024"
  api_task_ram             = "8192"
  desired_count_backend    = 2 
}