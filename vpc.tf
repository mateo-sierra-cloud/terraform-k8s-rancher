# DEPRECATED: This file has been moved to modules/network/main.tf
# 
# All VPC and networking resources are now managed in the network module.
#
# This file can be safely deleted after verifying the modular setup works.
#
# Resources moved to modules/network/main.tf:
# - aws_vpc.main
# - aws_subnet.public
# - aws_subnet.private
# - aws_internet_gateway.main
# - aws_nat_gateway.main
# - aws_eip.nat
# - aws_route_table.public
# - aws_route_table.private
# - aws_route_table_association.public
# - aws_route_table_association.private