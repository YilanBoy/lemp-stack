# filter option can refer to aws cli "describe-images"
# ref: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
data "aws_ami" "ubuntu_22_04_arm" {
  most_recent = true

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon_linux_arm" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu_22_04_arm.id
  instance_type = "t4g.micro"
  key_name      = aws_key_pair.ssh.key_name

  # vpc setting, place the instance in the specified subnet
  availability_zone = data.aws_availability_zones.available.names[0]
  subnet_id         = aws_subnet.public.id
  security_groups   = [aws_security_group.app.id]

  # when instance launched, execute the configuration tasks
  user_data_base64            = data.cloudinit_config.app_setup.rendered
  user_data_replace_on_change = true

  # Ubuntu community recommended minimum 15 GB of hard drive space
  # https://help.ubuntu.com/community/DiskSpace
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "app"
  }
}

data "cloudinit_config" "app_setup" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "01-update-package.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/update-package.sh")
  }

  part {
    filename     = "02-install-nginx.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-nginx.sh")
  }

  part {
    filename     = "03-install-php.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-php.sh")
  }

  part {
    filename     = "04-install-supervisor.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-supervisor.sh")
  }

  part {
    filename     = "05-install-awscli.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-awscli.sh")
  }

  part {
    filename     = "06-install-docker.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-docker.sh")
  }
}

# set security groups, similar to firewall
resource "aws_security_group" "app" {
  name   = "app_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app"
  }
}

resource "aws_instance" "database" {
  ami                         = data.aws_ami.ubuntu_22_04_arm.id
  instance_type               = "t4g.micro"
  key_name                    = aws_key_pair.ssh.key_name
  availability_zone           = data.aws_availability_zones.available.names[0]
  user_data_base64            = data.cloudinit_config.database_setup.rendered
  user_data_replace_on_change = true

  network_interface {
    network_interface_id = aws_network_interface.database.id
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    delete_on_termination = true
    encrypted             = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "database"
  }
}

data "cloudinit_config" "database_setup" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "01-update-package.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/update-package.sh")
  }

  part {
    filename     = "02-install-docker.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-docker.sh")
  }

  part {
    filename     = "03-run-mysql-container.sh"
    content_type = "text/x-shellscript"

    content = templatefile("scripts/run-mysql-container.sh", {
      mysql_database_name = var.mysql_database_name
      mysql_root_password = var.mysql_root_password
      mysql_user          = var.mysql_user
      mysql_password      = var.mysql_password
    })
  }
}

resource "aws_network_interface" "database" {
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.database.id]
  private_ips     = ["10.0.1.100"]

  tags = {
    Name = "database_network_interface"
  }
}

resource "aws_security_group" "database" {
  name   = "database_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database"
  }
}

resource "aws_instance" "redis" {
  ami                         = data.aws_ami.ubuntu_22_04_arm.id
  instance_type               = "t4g.micro"
  key_name                    = aws_key_pair.ssh.key_name
  availability_zone           = data.aws_availability_zones.available.names[0]
  user_data_base64            = data.cloudinit_config.redis_setup.rendered
  user_data_replace_on_change = true

  network_interface {
    network_interface_id = aws_network_interface.redis.id
    device_index         = 0
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 15
    delete_on_termination = true
    encrypted             = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "redis"
  }
}

resource "aws_network_interface" "redis" {
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.redis.id]
  private_ips     = ["10.0.1.101"]

  tags = {
    Name = "redis_network_interface"
  }
}

data "cloudinit_config" "redis_setup" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "01-update-package.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/update-package.sh")
  }

  part {
    filename     = "02-install-docker.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/install-docker.sh")
  }

  part {
    filename     = "03-run-redis-container.sh"
    content_type = "text/x-shellscript"

    content = templatefile("scripts/run-redis-container.sh", {
      redis_password = var.redis_password
    })
  }
}

resource "aws_security_group" "redis" {
  name   = "redis_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux_arm.id
  instance_type               = "t4g.nano"
  key_name                    = aws_key_pair.ssh.key_name
  availability_zone           = data.aws_availability_zones.available.names[0]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.nat.id]
  source_dest_check           = false
  user_data_base64            = data.cloudinit_config.nat_setup.rendered
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "nat"
  }
}

data "cloudinit_config" "nat_setup" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "01-update-package.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/update-package.sh")
  }

  part {
    filename     = "02-iptable-nat.sh"
    content_type = "text/x-shellscript"
    content      = file("scripts/iptable-nat.sh")
  }
}

resource "aws_security_group" "nat" {
  name   = "nat_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow NAT for all my promary vpc cidr"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow NAT out-going anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "nat"
  }
}

# set ssh key pair to connect the instance
resource "aws_key_pair" "ssh" {
  key_name   = "lemp_ssh_key"
  public_key = file(var.ssh_public_key_filepath)
}
