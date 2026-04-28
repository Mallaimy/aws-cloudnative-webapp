# security groupe resources
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-sg-"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-ecs-sg-"
  description = "Security group for Elastic Container Service"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.project_name}-db-sg-"
  description = "Security group for the PostgreSQL Database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# security group ingress(inbound) rules

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow app port from ALB"

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_ecs" {
  security_group_id = aws_security_group.db.id
  description       = "Allow db port from ECS"

  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# security groupe egress(outbound) rules
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 means "all protocols"
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 means "all protocols"
}
