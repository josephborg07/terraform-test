##Create LB

resource "aws_lb" "K8s-ALB" {
    name="K8s-ALB"
    internal="false"
    load_balancer_type="application"
    subnets=["${aws_subnet.K8s-TestSubnet1.id}", "${aws_subnet.K8s-TestSubnet2.id}"]
    security_groups=["${aws_vpc.K8s-TestVPC.default_security_group_id}"]

    tags{
        Name="K8s-ALB"
    }
}
#create LB target group
resource "aws_lb_target_group" "K8s-ALBResourceGroup" {
    name="K8s-ALBResourceGroup"
    vpc_id="${aws_vpc.K8s-TestVPC.id}"
    port="80"
    protocol="HTTP"  
    health_check{
        healthy_threshold   = "5"
        unhealthy_threshold = "2"
        interval            = "30"
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "5"        
    }
}
#Create listeners for target group
resource "aws_alb_listener" "alb-listener" {
    load_balancer_arn = "${aws_lb.K8s-ALB.arn}"
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_lb_target_group.K8s-ALBResourceGroup.arn}"
        type             = "forward"
    }
}