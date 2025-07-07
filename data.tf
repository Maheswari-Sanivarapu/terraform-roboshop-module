data "aws_ami" "joindevops_ami" {
    owners = ["973714476881"]
    most_recent = true
    filter {
        name   = "name"
        values = ["RHEL-9-DevOps-Practice"]
    }
}

data "aws_ssm_parameter" "vpc_id" {
  name  = "/${var.project}/${var.environment}/vpc_id"
}
data "aws_ssm_parameter" "private_subnet_id" {
  name  = "/${var.project}/${var.environment}/private_subnet_id"
}

data "aws_ssm_parameter" "sg_id" {
  name = "/${var.project}/${var.environment}/${var.component}_sg_id"
}

data "aws_ssm_parameter" "backend_alb_listener_arn" {
  name  = "/${var.project}/${var.environment}/backend_alb_listener_arn"
}

data "aws_ssm_parameter" "frontend_alb_listener_arn" {
  name  = "/${var.project}/${var.environment}/frontend_alb_listener_arn"
}