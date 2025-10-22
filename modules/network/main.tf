resource "aws_vpc" "this" {
  cidr_block = var.cidr
  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_subnet" "private" {
  count    = length(var.private_subnets)
  vpc_id   = aws_vpc.this.id
  cidr_block = var.private_subnets[count.index]
  tags = merge(var.tags, { Name = "${var.name}-private-${count.index}" })
}