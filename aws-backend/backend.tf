terraform {
  backend "s3" {
    bucket         = "refill-radar-cdc-tf-state"
    key            = "refill-radar/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}