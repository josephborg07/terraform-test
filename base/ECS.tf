#######################################
### 1. Create IAM ECS service role ####
#######################################
##Creates a new role named K8s-ecs-service-role
resource "aws_iam_role" "K8s-ecs-service-role" {
    name                = "K8s-ecs-service-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.K8s-ecs-service-policy.json}"
}
##Creating the policy document
data "aws_iam_policy_document" "K8s-ecs-service-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs.amazonaws.com"]
        }
    }
}
##Attaching an existing policy to the newly created IAM role and document 
resource "aws_iam_role_policy_attachment" "K8s-ecs-service-role-attachment" {
    role       = "${aws_iam_role.K8s-ecs-service-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}


#######################################
### 2. Create IAM ECS instance role ###
#######################################

#Create a new IAM role called K8s-ecs-instance-role
resource "aws_iam_role" "K8s-ecs-instance-role" {
    name                = "K8s-ecs-instance-role"
    path                = "/"
    assume_role_policy  = "${data.aws_iam_policy_document.K8s-ecs-instance-policy.json}"
}
#Create a new policy document which trusts ec2.amazonaws.com
data "aws_iam_policy_document" "K8s-ecs-instance-policy" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}
#Attach "K8s-ecs-instance-role" role to the "K8-ecs-instance-policy" policy
resource "aws_iam_role_policy_attachment" "K8s-ecs-instance-role-attachment" {
    role       = "${aws_iam_role.K8s-ecs-instance-role.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
#create profile
resource "aws_iam_instance_profile" "K8s-ecs-instance-profile" {
    name = "K8s-ecs-instance-profile"
    path = "/"
    roles = ["${aws_iam_role.K8s-ecs-instance-role.id}"]
    provisioner "local-exec" {
      command = "echo $Env:USERPROFILE"
      
    }
}

#######################################
### 3. Create Launch configuration ####
#######################################
###Launch configuration - Specifies what resources to scale using the autoscale group below

resource "aws_launch_configuration" "K8s-ecs-launch-configuration" {
    name                        = "K8s-ecs-launch-configuration"
    image_id                    = "ami-0653e888ec96eab9b"
    instance_type               = "t2.micro"
    iam_instance_profile        = "${aws_iam_instance_profile.K8s-ecs-instance-profile.id}"

    root_block_device {
      volume_type = "standard"
      volume_size = 100
      delete_on_termination = true
    }

    lifecycle {
      create_before_destroy = true
    }

    security_groups             = ["${aws_vpc.K8s-TestVPC.default_security_group_id}"]
    associate_public_ip_address = "true"
    key_name                    = "${var.ecs_key_pair_name}"
    user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${var.ecs_cluster} >> /etc/ecs/ecs.config
                                  EOF
}

#######################################
##### 4. Create autoscaling grouop ####
#######################################
#An autoscale group specifies the conditions by which to scale; the scaling conditions below 
#will scale according to the above resources

resource "aws_autoscaling_group" "K8s-ecs-autoscaling-group" {
    name                        = "K8s-ecs-autoscaling-group"
    max_size                    = "${var.max_instance_size}"
    min_size                    = "${var.min_instance_size}"
    desired_capacity            = "${var.desired_capacity}"
    vpc_zone_identifier         = ["${aws_subnet.K8s-TestSubnet1.id}", "${aws_subnet.K8s-TestSubnet2.id}"]
    launch_configuration        = "${aws_launch_configuration.K8s-ecs-launch-configuration.name}"
    health_check_type           = "ELB"
    target_group_arns           =["${aws_lb_target_group.K8s-ALBResourceGroup.arn}"]
  }
#######################################
###### 4. Create an ECS cluster #######
#######################################
  resource "aws_ecs_cluster" "K8s-ECSClusterWP" {
    name = "${var.ecs_cluster}"
}

############################################
###### 5. Create ECS task definition #######
############################################

resource "aws_ecs_task_definition" "wordpress" {
    family                = "hello_world"
    container_definitions = <<DEFINITION
[
  {
    "name": "wordpress",
    "links": [
      "mysql"
    ],
    "image": "wordpress",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "memory": 500,
    "cpu": 10
  },
  {
    "environment": [
      {
        "name": "MYSQL_ROOT_PASSWORD",
        "value": "password"
      }
    ],
    "name": "mysql",
    "image": "mysql",
    "cpu": 10,
    "memory": 500,
    "essential": true
  }
]
DEFINITION
}

data "aws_ecs_task_definition" "wordpress" {
  task_definition = "${aws_ecs_task_definition.wordpress.family}"
}

####################################
###### 6. Create ECS service #######
####################################
/*
resource "aws_ecs_service" "K8s-WPecs-service" {
  	name            = "K8s-WPecs-service"
  	iam_role        = "${aws_iam_role.K8s-ecs-service-role.name}"
  	cluster         = "${aws_ecs_cluster.K8s-ECSClusterWP.id}"
  	task_definition = "${aws_ecs_task_definition.wordpress.family}:${max("${aws_ecs_task_definition.wordpress.revision}", "${data.aws_ecs_task_definition.wordpress.revision}")}"
  	desired_count   = 2
  	load_balancer {
    	target_group_arn  = "${aws_lb_target_group.K8s-ALBResourceGroup.arn}"
    	container_port    = 80
    	container_name    = "wordpress"
	}
}
output "ECS Instances" {
  value = "${aws_ecs_service.K8s-WPecs-service.desired_count}"
}*/