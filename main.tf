## ecr
resource "aws_ecr_repository" "ecr_repository" {
  name                 = "site-prod"
  image_tag_mutability = "MUTABLE"
}

## Key pair
resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair-lab"
  public_key = var.public_key
}

## ec2
resource "aws_instance" "server" {
  ami           = "ami-0532be01f26a3de55"
  instance_type = "t3.micro"

  key_name = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.website_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = file("inst_docker.sh")

  tags = {
    Name        = "website-server"
    Provisioned = "Terraform"
  }
}

## Security group
resource "aws_security_group" "website_sg" {
  name   = "website-sg"
  vpc_id = "vpc-06e1491d6628e9ce9"

  tags = {
    Name        = "website-sg"
    Provisioned = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.website_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.website_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

## IAM role
resource "aws_iam_role" "ec2_role" {
  name = "role-ec2-devops"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "role-ec2-devops"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}
