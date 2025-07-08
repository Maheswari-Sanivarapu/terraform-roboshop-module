resource "aws_lb_target_group" "main" {
    name = "${var.project}-${var.environment}-${var.component}"
    port = local.tg_port
    protocol = "HTTP" 
    vpc_id = local.vpc_id
    health_check {
        healthy_threshold = 2 #Number of consecutive health check successes required before considering a target healthy. The range is 2-10. Defaults to 3.
        interval = 5 # Approximate amount of time, in seconds, between health checks of an individual target. The range is 5-300
        matcher = "200-299" # response code for health check it ranges from 200-299
        path = local.health_check_path # checking the health of the catalogue component
        port = local.tg_port # port which catalogue component is allowed
        timeout = 2 # after hitting the URL before 5 seconds we should get response or it is unhealthy
        unhealthy_threshold = 3 # to check the health of the instane we will use this if the instance fails after 3 attempts then it will mark it as unhealthy
    }   
}

# creating the instance for the frontend and backend components
resource "aws_instance" "main" {
    ami = local.ami_id
    instance_type = "t2.micro"
    vpc_security_group_ids = [local.sg_id] # taking the catalogue sg-id from 10-sg
    subnet_id = local.private_subnet_id # taking the prviate_subnet_id from 00-VPC
    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )
}

# configuring the frontend and backend component through filename.sh by taking the code from ansible roles
resource "terraform_data" "main" {
    triggers_replace = [
        aws_instance.main.id # once catalogue instance is created then this will trigger and take the latest catalogue id
    ]

    provisioner "file" {
        source = "bootstrap.sh"
        destination = "/tmp/${var.component}.sh"
    }

    connection {
        type = "ssh"
        user = "ec2-user"
        password = "DevOps321"
        host = aws_instance.main.private_ip # connecting to the instance through private_ip bcoz catalogue component  is in private subnet
    }
   
    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/${var.component}.sh", # executing this commands inside instance so using remote exec
            "sudo sh /tmp/${var.component}.sh ${var.component} ${var.environment}"
        ]
    }
}

# first stopping the instance
resource "aws_ec2_instance_state" "main" {
    instance_id = aws_instance.main.id
    state       = "stopped"
    depends_on = [terraform_data.main] # first configuring the required dependenices and packages once that is done so this stopping the instance is depends on configuration 
}

# take ami id from the instance
resource "aws_ami_from_instance" "main" {
    name = "${var.project}-${var.environment}-${var.component}"
    source_instance_id = aws_instance.main.id  # id of the instance to use it as base AMI Image, taking this from catalogue instance
    depends_on = [aws_ec2_instance_state.main] # this ami will be take once the instance is stopped here so this ami is dependent on stopping the instance
    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )
}

# terminate the instance
resource "terraform_data" "main_terminate" {
    triggers_replace = [
        aws_instance.main.id
    ]

  # make sure you have aws configure in your laptop
    provisioner "local-exec" {
        command = "aws ec2 terminate-instances --instance-ids ${aws_instance.main.id}" # deleting the instances
    }
    depends_on = [aws_ami_from_instance.main] # once it takes ami it will delete it
}

# here not creating the route53 record for catalogue bcoz it is already declared in alb like when user hits *.backend-dev.pavithra.fun 
# then it will forward it based on that *. so here using catalogue instead of *. for catalogue component i.e. catalogue-dev.pavithra.fun

# resource "aws_route53_record" "catalogue" {
#     zone_id = var.route53_zone_id
#     name = "catalogue-${var.environment}.${var.route53_domain_name}"
#     type = "A"
#     ttl = 1
#     records = [aws_instance.catalogue.private_ip]
#     allow_overwrite = true
# }

#creating the launch template to store the created AMI
# requires image-id,sg-id,instance_type,launch_template_name/name
resource "aws_launch_template" "main" {
    name = "${var.project}-${var.environment}-${var.component}"
    image_id = aws_ami_from_instance.main.id # image-id from aws_ami_from_instance
    instance_type = "t2.micro"
    instance_initiated_shutdown_behavior = "terminate" # once it took image-id it should be stopped or terminate
    vpc_security_group_ids = [local.sg_id] #sg-id of catalogue
    tag_specifications {
        resource_type = "instance" #instance here
        tags = merge(
            local.common_tags,
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            }
        )
    }
    tag_specifications {
        resource_type = "volume"
        tags = merge(
            local.common_tags,
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            }
        )
    }
    tags = merge(
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-${var.component}"
        }
    )
}


# creating Autoscaling group
# Requires Launch_template,availability_zone,target_group,desired_capacity,min,max,availability_zones,health_check_grace_period
resource "aws_autoscaling_group" "main" {
     name = "${var.project}-${var.environment}-${var.component}"
     desired_capacity = 1  # capacity to autoscale
     max_size = 10 # max size
     min_size = 1 # min size
     health_check_grace_period = 90 # once the instance is created how much it is used to initialize the instance
     health_check_type = "ELB" # here we are checking LB health check
     vpc_zone_identifier = local.private_subnet_ids # availability zones to add if one zone is down it will have another zone
     target_group_arns = [aws_lb_target_group.main.arn] # to where the traffic should route from listener based on the URL,based on the target group  
     launch_template {
        id = aws_launch_template.main.id # taking id from launch_template
        version = aws_launch_template.main.latest_version # taking version id from launch_template when every launch template is created new version will be there
     }
     dynamic "tag" {
        for_each = merge(
            local.common_tags,
            {
                Name = "${var.project}-${var.environment}-${var.component}"
            }
        )
        content{
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
     instance_refresh {
        strategy = "Rolling" # here once we got launch_template based on demand it will automatically increase/decrease the instances using rolling update
        preferences {
        min_healthy_percentage = 50
        }
        triggers = ["launch_template"] # when new launch_template is created it will automatically trigger and take that value
     }
     timeouts {
        delete = "15m"
    }
}

# auto-scaling policy based on the cpu or memory utilization it will autoscale so here taking cpu utilization
resource "aws_autoscaling_policy" "main" {
    name = "${var.project}-${var.environment}-${var.component}"
    autoscaling_group_name = aws_autoscaling_group.main.name # auto-scaling group name
    policy_type = "TargetTrackingScaling" # target to track this
    target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization" # cpu utilization
    }
    target_value = 75.0 # if it is more than 75% it will autoscale
  }
}

#listener rule
resource "aws_lb_listener_rule" "listener" {
    listener_arn = local.alb_listener # getting listener arn
    priority     = var.priority
    action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn # here forwarding the traffic to target group
    }
    condition {
        host_header {
            values = [local.request_header_url] #when anyone hits this URL forward to target group
        }
    }
}

