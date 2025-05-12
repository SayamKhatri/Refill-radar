variable "project" {
  description = "Name of the project"
  type        = string
  default     = "Refill-Radar"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.9"
}

variable "lambda_handler" {
  description = "Lambda function entrypoint"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "alert_email" {
  description = "Email address to subscribe to SNS alerts"
  type        = string
  default     = "1999sanyam@gmail.com"  
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_endpoint" {
  description = "RDS endpoint hostname"
  type        = string
}
