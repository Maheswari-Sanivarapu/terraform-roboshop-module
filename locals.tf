locals {
    ami_id = data.aws_ami.joindevops_ami.id
    private_subnet_id = split(",",data.aws_ssm_parameter.private_subnet_id.value)[0]
    private_subnet_ids = split(",",data.aws_ssm_parameter.private_subnet_id.value)
    tg_port = "${var.component}" == "frontend" ? 80 : 8080
    health = "${var.component}" == "frontend" ? "/" : "/health"
    sg_id = data.aws_ssm_parameter.sg_id.value
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    backend_alb_listener_arn = data.aws_ssm_parameter.backend_alb_listener_arn.value
    common_tags = {
        project = var.project
        environment = var.environment
    }
}