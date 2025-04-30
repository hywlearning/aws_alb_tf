output "infra_info" {
  value     = [
    {
    vpc=aws_vpc.main[0].id,
    ec2_jumphost_publicip= var.ec2_create? aws_instance.jumphost[0].public_ip : "",
    ec2-jumphost= var.ec2_create? aws_instance.jumphost[0].private_ip : "",
    ec2-blue= var.ec2_create ? [for i in aws_instance.blue-ec2 : i.private_ip] : []
    ec2-green= var.ec2_create ? [for i in aws_instance.green-ec2 : i.private_ip] : []
    }]
}
