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
  default     = "python3.12"
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
