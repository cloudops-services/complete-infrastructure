output "database_host" {
  value = aws_db_instance.rds_application_instance.address
}