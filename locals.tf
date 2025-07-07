locals {
    ami_id = data.aws_ami.joindevops_ami.id
    private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_id.value)[0]
    private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_id.value)
    tg_port = "${var.component}" == "frontend" ? 80 : 8080
    health = "${var.component}" == "frontend" ? "/" : "/health" 
    sg_id = data.aws_ssm_parameter.sg_id.value
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    backend_alb_listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value
    frontend_alb_listener_arn = data.aws_ssm_parameter.frontend_alb_listener_arn.value
    alb_listener = "${var.component}" == "frontend" ? local.frontend_alb_listener_arn : local.backend_alb_listener_arn
    frontend_domain_name = "${var.environment}.${var.route53_domain_name}"
    backend_domain_name = "${var.component}.backend-${var.environment}.${var.route53_domain_name}"
    domain_name = "${var.component}" == "frontend" ? local.frontend_domain_name : local.backend_domain_name
    common_tags = {
        project = var.project
        environment = var.environment
    }
}