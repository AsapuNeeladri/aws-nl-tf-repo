########################################
# Latest Amazon Linux 2023 AMI
########################################
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

########################################
# EC2 - Public instance
########################################
resource "aws_instance" "public_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "${local.project_name}-public-ec2"
  }
}

########################################
# EC2 - Private instance
########################################
resource "aws_instance" "private_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "${local.project_name}-private-ec2"
  }
}

########################################
# EBS data volume for the public instance
########################################
resource "aws_ebs_volume" "data" {
  availability_zone = local.availability_zone
  size              = 30
  type              = "gp3"
  encrypted         = true

  tags = {
    Name = "${local.project_name}-data-volume"
  }
}

resource "aws_volume_attachment" "data" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.data.id
  instance_id  = aws_instance.public_ec2.id
  force_detach = true
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ssm_association" "mount_data_volume" {
  name             = "AWS-RunShellScript"
  association_name = "${local.project_name}-mount-data-volume"
  depends_on       = [aws_volume_attachment.data, aws_iam_role_policy_attachment.ec2_ssm]

  targets {
    key    = "InstanceIds"
    values = [aws_instance.public_ec2.id]
  }

  parameters = {
    commands = <<-EOF
      set -e
      device="/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${replace(aws_ebs_volume.data.id, "-", "")}"
      for attempt in $(seq 1 60); do
        if [ -e "$device" ]; then break; fi
        sleep 5
      done
      test -e "$device"
      if ! blkid "$device" >/dev/null 2>&1; then mkfs -t xfs "$device"; fi
      mkdir -p /data
      uuid=$(blkid -s UUID -o value "$device")
      grep -q "UUID=$uuid /data" /etc/fstab || echo "UUID=$uuid /data xfs defaults,nofail 0 2" >> /etc/fstab
      mount -a
    EOF
  }
}
