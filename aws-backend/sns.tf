resource "aws_sns_topic" "stockout_alerts" {
  name = "stockout-alerts"

  tags = {
    Name        = "stockout-alerts"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.stockout_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}