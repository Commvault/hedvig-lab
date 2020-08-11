# Lab / demo purposes only. Not for production use

provider "aws" {
  region = var.region
}

resource "aws_vpc" "hedviglab" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.hedviglab.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.hedviglab.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "hedvig-public" {
  vpc_id                  = aws_vpc.hedviglab.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "hedvig-private" {
  vpc_id                  = aws_vpc.hedviglab.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
}

# Our default security group to access the instances over SSH and HTTP
resource "aws_security_group" "sg-public" {
  name   = "hedvig-sg-public"
  vpc_id = aws_vpc.hedviglab.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg-private" {
  name   = "hedvig-sg-private"
  vpc_id = aws_vpc.hedviglab.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.hedvig-public.cidr_block]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.hedvig-public.cidr_block]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.hedvig-public.cidr_block]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [aws_subnet.hedvig-public.cidr_block]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "hedvig-jump" {
  ami                    = var.image
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg-public.id]
  subnet_id              = aws_subnet.hedvig-public.id
  key_name               = var.keypair_name
  root_block_device {
    delete_on_termination = true
  }

  connection {
    type        = "ssh"
    user        = "centos"
    host        = self.public_ip
    private_key = file(var.key_path_private)
  }

  # Example install of web-sever to validate connectivity 
  provisioner "remote-exec" {
    inline = [
      "sudo yum -y install epel-release",
      "sudo yum -y install nginx",
      "sudo systemctl start nginx",
    ]
  }

}

resource "aws_instance" "hedvig-proxy" {
  ami                    = var.image
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg-private.id]
  subnet_id              = aws_subnet.hedvig-private.id
  key_name               = var.keypair_name

  root_block_device {
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "gp2"
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
}

resource "aws_instance" "hedvig-deployment" {
  ami                    = var.image
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg-private.id]
  subnet_id              = aws_subnet.hedvig-private.id
  key_name               = var.keypair_name

  root_block_device {
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "gp2"
    volume_size           = 40
    delete_on_termination = true
  }
}

resource "aws_instance" "hedvig-storage-node" {
  ami                    = var.image
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg-private.id]
  subnet_id              = aws_subnet.hedvig-private.id
  key_name               = var.keypair_name

  root_block_device {
    delete_on_termination = true
  }

  count = 3

  # OS
  ebs_block_device {
    device_name           = "/dev/sdg"
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }

  # Cache
  ebs_block_device {
    device_name           = "/dev/sdh"
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
  }

  # Metadata (1:10 with storage node)
  ebs_block_device {
    device_name           = "/dev/sdi"
    volume_type           = "io1"
    iops                  = 1000
    volume_size           = 64
    delete_on_termination = true
  }

  # Storage
  ebs_block_device {
    device_name           = "/dev/sdj"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdk"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdl"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdm"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdn"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdo"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdp"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdq"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }
  ebs_block_device {
    device_name           = "/dev/sdr"
    volume_type           = var.storage-node-volume-type
    volume_size           = var.storage-node-volume-size
    delete_on_termination = true
  }

}