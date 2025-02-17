# backend.tf

terraform {
  backend "s3" {
    bucket = "yh-test"  # S3 버킷 이름을 고유하게 설정하세요.
    key    = "terraform.tfstate"            # 상태 파일 이름
    region = "ap-northeast-2"               # AWS 리전
  }
}
