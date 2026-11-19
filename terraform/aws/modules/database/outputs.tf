output "address" {
  value = aws_db_instance.this.address
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}
