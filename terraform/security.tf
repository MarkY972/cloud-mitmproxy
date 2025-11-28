resource "aws_security_group" "mitmproxy_sg" {
  name        = "mitmproxy-saas-mitmproxy-sg"
  description = "Allow inbound traffic to the mitmproxy instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mitmproxy-saas-mitmproxy-sg"
  }
}
