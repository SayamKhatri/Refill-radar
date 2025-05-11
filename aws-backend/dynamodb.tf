resource "aws_dynamodb_table" "stockout_alerts" {
  name           = "stockout_alerts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "alert_id"

  attribute {
    name = "alert_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl_expiration"
    enabled        = true
  }

  tags = {
    Name        = "stockout_alerts"
    Environment = var.environment
    Project     = var.project
  }
}