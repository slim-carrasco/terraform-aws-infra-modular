resource "aws_s3_bucket" "this" {
  bucket = "frizka-terraform-state"
  
  tags = {   
    Name        = "terraform-state"   
    Environment = "shared"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "this" {
  name         = "tfstate"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = "lock-tfstate"
    Environment = "shared" 
  }
  
}
