variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "us-east-1"
}

variable "backend_image" {
  description = "The Docker image for the backend service."
  type        = string
  default     = "placeholder"
}

variable "frontend_image" {
  description = "The Docker image for the frontend service."
  type        = string
  default     = "placeholder"
}
