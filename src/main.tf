provider "aws" {
  region = "us-west-2" # Substitua pela região desejada
}

# Define o grupo de segurança para as instâncias EC2
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow inbound traffic on port 80 and 3306"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# Define o Load Balancer
resource "aws_elb" "lb" {
  name               = "my-lb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    protocol          = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "my-lb"
  }
}

# Define a instância EC2
resource "aws_instance" "worker" {
  count             = 5
  ami               = "ami-0c55b159cbfafe1f0" # Substitua pelo ID da AMI desejada
  instance_type     = "t2.micro"
  security_groups   = [aws_security_group.ec2_sg.name]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "worker-${count.index + 1}"
  }
}

# Define o banco de dados RDS
resource "aws_db_instance" "events" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  name                 = "events"
  username             = "admin"
  password             = "password" # Substitua pela senha desejada
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  tags = {
    Name = "events-db"
  }
}

# Cria uma associação entre o Load Balancer e as instâncias EC2
resource "aws_elb_attachment" "worker_attachment" {
  count      = 5
  elb        = aws_elb.lb.id
  instance_id = aws_instance.worker[count.index].id
}
