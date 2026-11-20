resource "aws_db_subnet_group" "this" {
  name       = "${lower(var.environment)}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

#tfsec:ignore:aws-rds-enable-performance-insights
#tfsec:ignore:aws-rds-enable-deletion-protection
resource "aws_db_instance" "this" {
  identifier     = "${lower(var.environment)}-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = var.db_name
  username                    = var.username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  multi_az               = false

  iam_database_authentication_enabled = true
  backup_retention_period             = 7
  auto_minor_version_upgrade          = true
  skip_final_snapshot                 = true
  #tfsec:ignore:AVD-AWS-0177
  deletion_protection = false

  tags = {
    Name = "${var.environment}-postgres"
  }
}
