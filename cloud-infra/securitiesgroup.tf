# ALB Security Group
resource "aws_security_group" "alb-sg" {
  count = var.ec2_create && var.vpc_create ? 1 : 0 
  name   = "ALB security group"
  vpc_id = aws_vpc.main[0].id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    cidr_blocks     = var.ssh_ingress_cidrblock_all
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    cidr_blocks     = var.ssh_ingress_cidrblock_all
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.ssh_egress_cidrblock_all
  }

}

# JUMPHOST
resource "aws_security_group" "sg-jumphost" {
  count = var.ec2_create && var.vpc_create ? 1 : 0 
  name   = "Jumhost security group"
  vpc_id = aws_vpc.main[0].id

  # Allow SSH to Jump Host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = var.ssh_ingress_cidrblock_all
  }

  # Allow all internal traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.ssh_egress_cidrblock_all
  }

}

# EC2 Security Group
resource "aws_security_group" "private-alb-sg" {
  count = var.ec2_create && var.vpc_create ? 1 : 0 
  name   = "EC2 network security group"
  vpc_id = aws_vpc.main[0].id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.sg-jumphost[0].id]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    security_groups    = [aws_security_group.alb-sg[0].id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    security_groups     =[aws_security_group.alb-sg[0].id]
  }
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [ aws_security_group.alb-sg, ]
}
