################################################
############ 1. Networking section #############
################################################

### 1.1 VPC creation
####################
resource "aws_vpc" "OrleansCluster-Vpc"{
	cidr_block = "192.168.0.0/16"
	instance_tenancy = "default"
	enable_dns_hostnames="True"
	tags{
		Name="OrleansCluster-Vpc"
	}
}

### 1.2 Subnet creation
#######################
resource "aws_subnet" "OrleansCluster-Subnet1"{
	vpc_id = "${aws_vpc.OrleansCluster-Vpc.id}"
	cidr_block = "192.168.0.0/24"
	map_public_ip_on_launch="True"
	availability_zone = "us-east-2a"
	tags{
		Name="OrleansCluster-Subnet1"
	}
}

resource "aws_subnet" "OrleansCluster-Subnet2"{
	vpc_id = "${aws_vpc.OrleansCluster-Vpc.id}"
	cidr_block = "192.168.1.0/24"
	map_public_ip_on_launch="True"
	availability_zone = "us-east-2b"
	tags{
		Name="OrleansCluster-Subnet2"
	}
}

resource "aws_subnet" "OrleansCluster-Subnet3"{
	vpc_id = "${aws_vpc.OrleansCluster-Vpc.id}"
	cidr_block = "192.168.2.0/24"
	availability_zone = "us-east-2c"
	tags{
		Name="OrleansCluster-Subnet3"
	}
}

### 1.3 Internet Gateway creation
#################################
resource "aws_internet_gateway" "OrleansCluster-InterneGateway" {
  vpc_id = "${aws_vpc.OrleansCluster-Vpc.id}"
  tags{
	  Name="OrleansCluster-InternetGateway"
  }
}
resource "aws_route" "OrleansCluster-PublicTrafficRoute" {
	route_table_id = "${aws_vpc.OrleansCluster-Vpc.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.OrleansCluster-InterneGateway.id}"
}


### 1.4 Subnet - route table association
resource "aws_route_table_association" "OrleansCluster-RTSubnetAssociation1" {
	subnet_id = "${aws_subnet.OrleansCluster-Subnet1.id}"
	route_table_id = "${aws_vpc.OrleansCluster-Vpc.main_route_table_id}"	
}

resource "aws_route_table_association" "OrleansCluster-RTSubnetAssociation2" {
	subnet_id = "${aws_subnet.OrleansCluster-Subnet2.id}"
	route_table_id = "${aws_vpc.OrleansCluster-Vpc.main_route_table_id}"	
}

resource "aws_network_acl_rule" "OrleansCluster-AclAllowSSH" {
	network_acl_id = "${aws_vpc.OrleansCluster-Vpc.default_network_acl_id}"
	rule_number="10"
	protocol="tcp"
	from_port="22"
	to_port="22"
	cidr_block="0.0.0.0/0"
	rule_action="Allow"  
}

## 1.5 - Create Security group rules
####################################
#1.5.1 - Allow SSH
resource "aws_security_group_rule" "OrleansCluster-SgAllowSSH"{
	security_group_id = "${aws_vpc.OrleansCluster-Vpc.default_security_group_id}"
	type="ingress"
	from_port="22"
	to_port="22"
	protocol="tcp"
	cidr_blocks=["0.0.0.0/0"]
}
#1.5.2 Allow HTTP
resource "aws_security_group_rule" "OrleansCluster-AllowHttp"{
	security_group_id = "${aws_vpc.OrleansCluster-Vpc.default_security_group_id}"
	type="ingress"
	from_port="80"
	to_port="80"
	protocol="tcp"
	cidr_blocks=["0.0.0.0/0"]
}

resource "aws_instance" "OrleansCluster-VM" {
  ami ="ami-02e680c4540db351e"
  instance_type = "t2.micro"
  security_groups = ["${aws_vpc.OrleansCluster-Vpc.default_security_group_id}"]
  subnet_id ="${aws_subnet.OrleansCluster-Subnet1.id}"
  key_name="${var.key_name}"
  count=2
  tags{
	  Name=  "OracleCluster-VM${count.index}"
  }
}

#######################
######## Outputs ######
#######################

output "OrleansCluster-VpcId" {
  value = "${aws_vpc.OrleansCluster-Vpc.id}"
}
output "OrleansCluster-Subnet1Id" {
  value = "${aws_subnet.OrleansCluster-Subnet1.id}"
}

output "OrleansCluster-SecurityGroupId" {
  value = "${aws_vpc.OrleansCluster-Vpc.default_security_group_id}"
}

output "OrleansCluster-VpcCidrBlock" {
  value = "${aws_vpc.OrleansCluster-Vpc.cidr_block}"
}

