resource "aws_vpc" "main" {
  count = var.vpc_create ? 1 : 0
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.prj_name}_alb_vpc"
  }
}

#create subnet
resource "aws_subnet" "public" {
  count = var.vpc_create ? length(var.main_public_subnet_cidr) : 0
  vpc_id     = aws_vpc.main[0].id
  cidr_block = var.main_public_subnet_cidr[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = merge(
   { Name = "${var.prj_name}-public-alb-${element(data.aws_availability_zones.available.names, count.index)}" },
    var.common_tags,
    )
}
  

resource "aws_subnet" "private" {
  count = var.vpc_create ? length(var.main_private_subnet_cidr) : 0
  vpc_id     = aws_vpc.main[0].id
  cidr_block = var.main_private_subnet_cidr[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = merge(
   { Name = "${var.prj_name}-private-alb-${element(data.aws_availability_zones.available.names, count.index)}" },
    var.common_tags
    )
}


#internet gateway
resource "aws_internet_gateway" "igw" {
  count = var.vpc_create ? 1 : 0
  vpc_id = aws_vpc.main[0].id

 tags = merge(
    { Name = "${var.prj_name}-igw"},
      var.common_tags
  )
}
#EIP
resource "aws_eip" "nat_eip" {
  count = var.vpc_create ? 1:0
  domain   = "vpc"
   tags = merge(
    { Name = "${var.prj_name}-nat-eip"},
      var.common_tags
  )
  depends_on = [ aws_internet_gateway.igw ]
}
#NAT
resource "aws_nat_gateway" "ngw" {
  count = var.vpc_create ? 1 : 0 //length(var.main_public_subnet_cidr)>0 ? length(var.main_public_subnet_cidr) :0
  allocation_id = element(aws_eip.nat_eip.*.id,count.index)
  subnet_id     = element(aws_subnet.public.*.id,count.index)

  
  tags = merge(
    { Name = "${var.prj_name}-ngw"},
      var.common_tags
  )

  depends_on = [ aws_internet_gateway.igw , aws_eip.nat_eip]
}

#routetable public
resource "aws_route_table" "rtb_public" {
  count = var.vpc_create ? 1 :0
  vpc_id = aws_vpc.main[0].id

  depends_on = [ aws_internet_gateway.igw ]

  tags = merge(
    { Name = "${var.prj_name}-public-rtb"},
      var.common_tags
  )
}

resource "aws_route" "public_rt" {
  count = var.vpc_create ? 1 :0
  route_table_id         = aws_route_table.rtb_public[0].id
  destination_cidr_block = var.all_access
  gateway_id = aws_internet_gateway.igw[0].id
}


resource "aws_route_table_association" "public_rtb_association" {
  count = var.vpc_create && length(var.main_public_subnet_cidr)>0 ? length(var.main_public_subnet_cidr) :0
  subnet_id      = element(aws_subnet.public.*.id,count.index)
  route_table_id = aws_route_table.rtb_public[0].id
}

#private routetable
resource "aws_route_table" "rtb_nat" {
  count = var.vpc_create ? 1 : 0
  vpc_id = aws_vpc.main[0].id

  tags = merge(
    { Name = "${var.prj_name}-nat-rtb"},
      var.common_tags
  )
}

resource "aws_route" "nat_route" {
  count = var.vpc_create ? 1 : 0
  route_table_id         = aws_route_table.rtb_nat[0].id
  destination_cidr_block = var.all_access
  gateway_id = aws_nat_gateway.ngw[0].id
}


resource "aws_route_table_association" "nat_rtb_association" {
  count = var.vpc_create && length(var.main_private_subnet_cidr)>0 ? length(var.main_private_subnet_cidr) :0
  subnet_id      = element(aws_subnet.private.*.id,count.index)
  route_table_id = aws_route_table.rtb_nat[0].id
}



