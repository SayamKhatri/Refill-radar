resource "aws_kinesis_stream" "inventory_stream" {
  name             = "inventory-cdc-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Name        = "inventory-cdc-stream"
    Environment = var.environment
    Project     = var.project
  }
}
