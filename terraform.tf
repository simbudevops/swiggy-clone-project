terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"     #change region as per your requirement
}

resource "aws_instance" "slack" {
  ami                    = "ami-0388e3ada3d9812da"      #change ami id for different region
  instance_type          = "m7i-flex.large"
  key_name               = "testing-1"              #change key name as per your setup
  vpc_security_group_ids = [aws_security_group.GitHubAction-VM-SG.id]
  user_data              = templatefile("./install.sh", {})

  tags = {
    Name = "GitHubAction-SonarQube"
  }

  root_block_device {
    volume_size = 40
  }
}

resource "aws_security_group" "GitHubAction-VM-SG" {
  name        = "GitHubAction-VM-SG"
  description = "Allow TLS inbound traffic"

  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "GitHubAction-VM-SG"
  }
}

output "public_ip" {
  value = aws_instance.slack.public_ip
}
