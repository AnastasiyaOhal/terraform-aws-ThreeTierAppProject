# NOTE! There are some parts that you need to change and uncomment. Pay attention to comments.

resource "aws_rds_cluster" "project" {
  cluster_identifier        = "project"
  availability_zones        = var.availability_zones
  engine                    = "mysql"
  db_cluster_instance_class = "db.m5d.large"
  storage_type              = "io1"
  allocated_storage         = 100
  iops                      = 1000
  master_username           = var.db_info[1]
  master_password           = var.db_info[2]
  database_name             = var.db_info[0]
  db_subnet_group_name      = aws_db_subnet_group.private_subnet.name
  skip_final_snapshot       = true
 # enable_http_endpoint      = true
  vpc_security_group_ids    = [aws_security_group.projectSG_RDS.id]
}

resource "aws_db_subnet_group" "private_subnet" {
  name        = "private_subnet_group"
  subnet_ids  = aws_subnet.private_subnet[*].id
  tags = {
    name = "private subnet group"
  }
}
