resource "aws_dms_replication_subnet_group" "default" {
  replication_subnet_group_id = "refill-radar-subnet-group"
  replication_subnet_group_description = "Subnet group for DMS to access RDS and Kinesis"
  subnet_ids = [
    "subnet-0cb61addfbe2c8bae",
    "subnet-034db9c96640e3fc0",
    "subnet-07e4a63a55ef8eb66",
    "subnet-067660dafc959ceb0",
    "subnet-0866a80fa92f50800",
    "subnet-07c7c99fbf650c8d2"
  ]

  depends_on = [time_sleep.wait_for_iam_propagation]

  tags = {
    Name        = "refill-radar-subnet-group"
    Environment = "dev"
    Project     = "Refill-Radar"
  }
}


resource "aws_dms_replication_instance" "default" {
  replication_instance_id        = "refill-radar-dms-instance"
  replication_instance_class     = "dms.t3.micro"
  allocated_storage              = 50
  publicly_accessible            = true
  multi_az                       = false
  replication_subnet_group_id    = aws_dms_replication_subnet_group.default.replication_subnet_group_id

  depends_on = [time_sleep.wait_for_iam_propagation
  ]

  tags = {
    Name        = "refill-radar-dms-instance"
    Environment = "dev"
    Project     = "Refill-Radar"
  }
}

resource "aws_dms_endpoint" "source_mysql" {
  endpoint_id     = "retail-mysql-source"
  endpoint_type   = "source"
  engine_name     = "mysql"
  username        = var.rds_username
  password        = var.rds_password
  server_name     = var.rds_endpoint
  port            = 3306
  database_name   = "HASP"

  tags = {
    Name        = "retail-mysql-source"
    Environment = "dev"
    Project     = "Refill-Radar"
  }
}

resource "aws_dms_endpoint" "target_kinesis" {
  endpoint_id       = "inventory-kinesis-target"
  endpoint_type     = "target"
  engine_name       = "kinesis"
  kinesis_settings {
    stream_arn            = aws_kinesis_stream.inventory_stream.arn
    message_format        = "json"
    service_access_role_arn = aws_iam_role.dms_kinesis_access.arn
  }

  tags = {
    Name        = "inventory-kinesis-target"
    Environment = "dev"
    Project     = "Refill-Radar"
  }
}


resource "aws_dms_replication_task" "cdc_task" {
  replication_task_id          = "refill-radar-cdc-task"
  migration_type               = "cdc"
  replication_instance_arn     = aws_dms_replication_instance.default.replication_instance_arn
  source_endpoint_arn          = aws_dms_endpoint.source_mysql.endpoint_arn
  target_endpoint_arn          = aws_dms_endpoint.target_kinesis.endpoint_arn
  replication_task_settings    = file("dms-task-settings.json")

  table_mappings = jsonencode({
    rules: [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = "HASP"
          table-name  = "inventory"
        }
        rule-action = "include"
      }
    ]
  })

  tags = {
    Name        = "refill-radar-cdc-task"
    Environment = "dev"
    Project     = "Refill-Radar"
  }
}
