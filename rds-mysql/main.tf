provider "aws" {
    region     = "ap-south-1"
}


resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
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

resource "aws_db_instance" "primary" {
  engine                 = "mysql"
  db_name                = "mywezvadb"
  identifier             = "wezvadb-main"
  instance_class         = "db.t3.micro"
  engine_version         = "8.0.41"
  allocated_storage      = 20
  publicly_accessible    = true
  username               = "admin"
  password               = "wezvatech"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  # Enable automated backups, High Availability, Auto upgrades
  backup_window           = "18:00-19:00"
  backup_retention_period = 7
  multi_az                = true
  maintenance_window      = "Sun:10:00-Sun:11:00"

  # Enable enhanced monitoring and specify the IAM role
  monitoring_interval = 60 # Interval in seconds
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring_role.arn
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery", "audit"]

  tags = {
    Name = "wezvadb"
  }
}


# Define the IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_enhanced_monitoring_role" {
  name = "rds-enhanced-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring_attachment" {
  role       = aws_iam_role.rds_enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

