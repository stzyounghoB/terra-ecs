terraform {
  backend "s3" {
    bucket         = "yh-terra-ecs"
    key            = "terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
  }
}
