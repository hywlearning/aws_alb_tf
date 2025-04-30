resource "aws_lb" "alb-blue-green" {
  name               = "alb-blue-green"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg[0].id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

    tags = merge(
        { Name = "${var.prj_name}_alb" },
        var.common_tags
    )

    depends_on = [ aws_s3_bucket.s3_alb,aws_s3_bucket_policy.alb_logging_policy ]
 
}

resource "aws_lb_target_group" "alb-tg-blue-http" {
  name        = "blue-group-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main[0].id

  depends_on = [ aws_instance.blue-ec2 ]

  tags = merge(
    { Name = "${var.prj_name}_blue_alb_http" },
    var.common_tags
  )

}


resource "aws_lb_target_group" "alb-tg-blue-https" {
  name        = "blue-group-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main[0].id

  depends_on = [ aws_instance.blue-ec2 ]

  tags = merge(
    { Name = "${var.prj_name}-blue-alb-https" },
    var.common_tags
  )

}

resource "aws_lb_listener" "alb-blue-httplistener" {
  load_balancer_arn = aws_lb.alb-blue-green.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg-blue-http.arn
  }

  depends_on = [ aws_lb.alb-blue-green, aws_lb_target_group.alb-tg-blue-http]
}

resource "aws_lb_listener" "alb-blue-https-listener" {
 load_balancer_arn = aws_lb.alb-blue-green.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.hbh_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg-blue-https.arn
  }

  depends_on = [ aws_lb.alb-blue-green, aws_lb_target_group.alb-tg-blue-https]
}

resource "aws_lb_target_group_attachment" "blue-ec2" {
  count = var.ec2_create && var.vpc_create ? length(var.main_private_subnet_cidr) : 0
  target_group_arn = aws_lb_target_group.alb-tg-blue-http.arn
  target_id        = aws_instance.blue-ec2[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "blue-ec2-https" {
  count = var.ec2_create && var.vpc_create ? length(var.main_private_subnet_cidr) : 0
  target_group_arn = aws_lb_target_group.alb-tg-blue-https.arn
  target_id        = aws_instance.blue-ec2[count.index].id
  port             = 443
}

#green

resource "aws_lb_target_group" "alb-tg-green-http" {
  name        = "green-group-http"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main[0].id

  depends_on = [ aws_instance.green-ec2 ]

  tags = merge(
    { Name = "${var.prj_name}-green-alb-http" },
    var.common_tags
  )
}

resource "aws_lb_target_group" "alb-tg-green-https" {
  name        = "green-group-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main[0].id

  depends_on = [ aws_instance.green-ec2 ]

  tags = merge(
    { Name = "${var.prj_name}-green-alb-https" },
    var.common_tags
  )
}

resource "aws_lb_target_group_attachment" "green-ec2" {
  count = var.ec2_create && var.vpc_create ? length(var.main_private_subnet_cidr) : 0
  target_group_arn = aws_lb_target_group.alb-tg-green-http.arn
  target_id        = aws_instance.green-ec2[count.index].id
  port             = 80
}


