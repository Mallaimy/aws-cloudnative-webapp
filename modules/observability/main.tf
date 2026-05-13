resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ====================================================
      # USER LAYER (ALB metrics) — y=0
      # ====================================================
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer", "${var.alb_arn_suffix}"
            ],
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "ALB Request Count (sum per 5 min)"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer", "${var.alb_arn_suffix}"
            ],
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "ALB 5XX Errors from Targets (sum per 5 min)"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer", "${var.alb_arn_suffix}"
            ],
          ]
          period = 300
          stat   = "p99"
          region = var.region
          title  = "ALB Target Response Time (p99)"
          legend = {
            position = "right"
          }
        }
      },

      # ====================================================
      # COMPUTE LAYER (ECS metrics) — y=6
      # ====================================================
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", "${var.cluster_name}",
              "ServiceName", "${var.service_name}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ECS Service CPU (avg across tasks)"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName", "${var.cluster_name}",
              "ServiceName", "${var.service_name}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ECS Service Memory (avg across tasks)"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "ECS/ContainerInsights",
              "RunningTaskCount",
              "ClusterName", "${var.cluster_name}",
              "ServiceName", "${var.service_name}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ECS Running Task Count"
          legend = {
            position = "right"
          }
        }
      },
      # ====================================================
      # Database LAYER (PostgreSql metrics) — y=12
      # ====================================================
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier", "${var.db_instance_identifier}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "DB CPU Utilization"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier", "${var.db_instance_identifier}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "DB connection numbre on average"
          legend = {
            position = "right"
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 12
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier", "${var.db_instance_identifier}"
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Remaining free DB storage"
          legend = {
            position = "right"
          }
        }
      },
    ]
  })
}
