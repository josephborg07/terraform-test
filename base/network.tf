################################################
############ 1. Networking section #############
################################################

### 1.1 VPC creation
####################
resource "aws_vpc" "K8s-TestVPC"{
	cidr_block = "192.168.0.0/16"
	instance_tenancy = "default"
	enable_dns_hostnames="True"
	tags{
		Name="K8s-TestVpc"
	}
}

### 1.2 Subnet creation
#######################
resource "aws_subnet" "K8s-TestSubnet1"{
	vpc_id = "${aws_vpc.K8s-TestVPC.id}"
	cidr_block = "192.168.0.0/24"
	map_public_ip_on_launch="True"
	availability_zone = "us-east-2a"
	tags{
		Name="K8s-TestSubnet1"
	}
}

resource "aws_subnet" "K8s-TestSubnet2"{
	vpc_id = "${aws_vpc.K8s-TestVPC.id}"
	cidr_block = "192.168.1.0/24"
	map_public_ip_on_launch="True"
	availability_zone = "us-east-2b"
	tags{
		Name="K8s-TestSubnet2"
	}
}

resource "aws_subnet" "K8s-TestSubnet3"{
	vpc_id = "${aws_vpc.K8s-TestVPC.id}"
	cidr_block = "192.168.2.0/24"
	availability_zone = "us-east-2c"
	tags{
		Name="K8s-TestSubnet3	"
	}
}

### 1.3 Internet Gateway creation
#################################
resource "aws_internet_gateway" "K8s-testIG" {
  vpc_id = "${aws_vpc.K8s-TestVPC.id}"
  tags{
	  Name="K8s-testIG"
  }
}
resource "aws_route" "K8s-PublicTraffic" {
	route_table_id = "${aws_vpc.K8s-TestVPC.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.K8s-testIG.id}"
}


### 1.4 Subnet - route table association
resource "aws_route_table_association" "K8s-TestRTSubnetAssociation1" {
	subnet_id = "${aws_subnet.K8s-TestSubnet1.id}"
	route_table_id = "${aws_vpc.K8s-TestVPC.main_route_table_id}"	
}

resource "aws_route_table_association" "K8s-TestRTSubnetAssociation2" {
	subnet_id = "${aws_subnet.K8s-TestSubnet2.id}"
	route_table_id = "${aws_vpc.K8s-TestVPC.main_route_table_id}"	
}

resource "aws_network_acl_rule" "AllowSSH" {
	network_acl_id = "${aws_vpc.K8s-TestVPC.default_network_acl_id}"
	rule_number="10"
	protocol="tcp"
	from_port="22"
	to_port="22"
	cidr_block="0.0.0.0/0"
	rule_action="Allow"  
}

## 1.5 - Create Security group rules
####################################
resource "aws_security_group_rule" "AllowSSH"{
	security_group_id = "${aws_vpc.K8s-TestVPC.default_security_group_id}"
	type="ingress"
	from_port="22"
	to_port="22"
	protocol="tcp"
	cidr_blocks=["0.0.0.0/0"]
}

resource "aws_security_group_rule" "AllowHttp"{
	security_group_id = "${aws_vpc.K8s-TestVPC.default_security_group_id}"
	type="ingress"
	from_port="80"
	to_port="80"
	protocol="tcp"
	cidr_blocks=["0.0.0.0/0"]
}

#######################
######## Outputs ######
#######################

output "K8s-vpc_id" {
  value = "${aws_vpc.K8s-TestVPC.id}"
}
output "K8s-subnet_id_1" {
  value = "${aws_subnet.K8s-TestSubnet1.id}"
}

output "K8s-security_group_id" {
  value = "${aws_vpc.K8s-TestVPC.default_security_group_id}"
}

output "vpc_id" {
  value = "${aws_vpc.K8s-TestVPC.cidr_block}"
}