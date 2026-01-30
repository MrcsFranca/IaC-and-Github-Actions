terraform {
  backend "s3" {
    bucket  = "terraform-lab02-devops"
    key     = "projeto-devops/terrafom.tfstate"
    region  = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}
