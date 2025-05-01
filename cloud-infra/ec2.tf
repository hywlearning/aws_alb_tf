resource "aws_s3_bucket" "s3_alb" {
  bucket = "${var.prj_name}-s3"
 force_destroy = true
  tags = {
    Name        = "${var.prj_name}-s3"
    Environment = var.prj_environment
  }
}

data "aws_ami" "ubuntu" {
  count = var.vpc_create && var.ec2_create ? 1 : 0
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] 
}


resource "aws_instance" "blue-ec2" {
  count       = var.ec2_create && var.vpc_create ? length(var.main_private_subnet_cidr) : 0 
  ami           = data.aws_ami.ubuntu[0].id
  instance_type = var.ec2_webserver.instance_type
  subnet_id = aws_subnet.private[count.index].id
  key_name = var.hellobag_keypair
  vpc_security_group_ids = [aws_security_group.private-alb-sg[0].id]
  associate_public_ip_address = false
  user_data = file(var.webserver_setup[count.index])
  
  root_block_device {
    delete_on_termination = true  # Delete when instance terminates
  }
  
  tags = merge(
    { Name = "${var.prj_name}-blue-ec2-${count.index+1}"},
      var.common_tags
  )

  depends_on = [ aws_eip.nat_eip ,aws_nat_gateway.ngw]
}

resource "aws_instance" "green-ec2" {
  count       = var.ec2_create && var.vpc_create ? length(var.main_private_subnet_cidr) : 0 
  ami           = data.aws_ami.ubuntu[0].id
  instance_type = var.ec2_webserver.instance_type
  subnet_id = aws_subnet.private[count.index].id
  key_name = var.hellobag_keypair
  vpc_security_group_ids = [aws_security_group.private-alb-sg[0].id]
  associate_public_ip_address = false
  user_data = file("templates/webserver.sh")
  
  root_block_device {
    delete_on_termination = true  # Delete when instance terminates
  }
  
  tags = merge(
    { Name = "${var.prj_name}-green-ec2-${count.index+1}"},
      var.common_tags
  )

  depends_on = [ aws_eip.nat_eip ,aws_nat_gateway.ngw]
}

resource "aws_instance" "jumphost" {
  count       = var.ec2_create && var.vpc_create ? 1 : 0 
  ami           = data.aws_ami.ubuntu[0].id
  instance_type = var.ec2_jumphost.instance_type
  subnet_id = aws_subnet.public[0].id
  key_name = var.hellobag_keypair
  vpc_security_group_ids = [aws_security_group.sg-jumphost[0].id]
  associate_public_ip_address = true
  iam_instance_profile =aws_iam_instance_profile.admin-instance-profile.name
  tags = merge(
    { Name = "${var.prj_name}-jumphost-ec2"},
      var.common_tags
  )
  depends_on = [ aws_eip.nat_eip ,aws_nat_gateway.ngw]

}