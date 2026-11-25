resource "aws_db_subnet_group" "this" {
  name       = "${lower(var.environment)}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

data "aws_resourcegroupstaggingapi_resources" "snapshots" {
  resource_type_filters = ["rds:snapshot"]

  tag_filter {
    key    = "Name"
    values = ["${var.environment}-postgres"]
  }
}

data "aws_db_snapshot" "latest" {
  count                  = length(data.aws_resourcegroupstaggingapi_resources.snapshots.resource_tag_mapping_list) > 0 ? 1 : 0
  db_instance_identifier = "${lower(var.environment)}-postgres"
  most_recent            = true
}

resource "random_id" "final_snapshot" {
  byte_length = 4
}

#tfsec:ignore:aws-rds-enable-performance-insights
#tfsec:ignore:aws-rds-enable-deletion-protection
resource "aws_db_instance" "this" {
  identifier          = "${lower(var.environment)}-postgres"
  engine              = "postgres"
  engine_version      = "16"
  instance_class      = var.instance_class
  snapshot_identifier = try(data.aws_db_snapshot.latest[0].db_snapshot_identifier, null)

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
  copy_tags_to_snapshot               = true
  auto_minor_version_upgrade          = true
  skip_final_snapshot                 = false
  final_snapshot_identifier           = "${lower(var.environment)}-postgres-final-${random_id.final_snapshot.hex}"
  #tfsec:ignore:AVD-AWS-0177
  deletion_protection = false

  tags = {
    Name = "${var.environment}-postgres"
  }

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}
