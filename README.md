# AWS Cloud-Native Web Application

A production-style multi-AZ AWS architecture built with Terraform, designed to demonstrate real-world DevOps and cloud engineering practices for portfolio purposes.

## Current State — Phase 2: Compute Layer ✅

A complete multi-AZ networking layer, fully reproducible from code:

- **Custom VPC** (`10.0.0.0/16`) with DNS support enabled
- **6 subnets across 2 Availability Zones** in 3 tiers:
  - Public (`10.0.0.0/24`, `10.0.1.0/24`) — for the load balancer
  - Private (`10.0.10.0/24`, `10.0.11.0/24`) — for application compute
  - Database (`10.0.20.0/24`, `10.0.21.0/24`) — isolated for RDS
- **Internet Gateway** attached to the VPC
- **NAT Gateway** in a public subnet (single-AZ deployment as a deliberate cost tradeoff for this project — production would use one NAT per AZ)
- **3 route tables** enforcing defense-in-depth:
  - Public route table → IGW
  - Private route table → NAT Gateway
  - Database route table → no internet route at all (only the local VPC route), preventing data exfiltration in case of compromise

### Security Layer

A defense-in-depth security group chain enforcing strict traffic flow:

- **ALB Security Group** — accepts HTTP (80) and HTTPS (443) from the internet
- **ECS Security Group** — accepts traffic only from the ALB security group, on the application port
- **DB Security Group** — accepts traffic only from the ECS security group, on the PostgreSQL port (5432)

The chain is enforced through security group references, not IP ranges:

```
   Internet
      │
      │  HTTP (80) / HTTPS (443)
      ▼
┌──────────────┐
│   ALB SG     │
└──────┬───────┘
       │
       │  app port (8080)
       ▼
┌──────────────┐
│   ECS SG     │
└──────┬───────┘
       │
       │  PostgreSQL (5432)
       ▼
┌──────────────┐
│    DB SG     │
└──────────────┘

  Each arrow is a deliberate ingress rule.
  Everything else is implicitly denied.
```

### Security engineering decisions

- **No DB egress rule.** The database security group has zero outbound permissions. Security groups are stateful, so return traffic to ECS connections is allowed automatically — no egress needed for legitimate replies. Blocking egress prevents the database from initiating outbound connections, closing the data exfiltration vector even if the database is compromised.
- **`name_prefix` instead of fixed names.** Combined with `lifecycle { create_before_destroy = true }`, this enables zero-downtime SG replacement. Fixed names cause deadlocks when an SG attached to a running resource needs replacement: AWS won't delete it, and a new SG can't take the same name.
- **Modern rule resources.** Each rule is a separate `aws_vpc_security_group_ingress_rule` or `aws_vpc_security_group_egress_rule` resource. This gives surgical control over rules — adding, removing, or auditing one rule doesn't affect the others. The older inline-rule pattern caused Terraform to try to delete rules added by other tools or teams.
- **Security group references over IP ranges.** Rules say "allow from ECS SG" not "allow from 10.0.10.0/24". The rules describe intent, are immune to IP changes, and remain correct even if subnet CIDRs are renumbered.

### Compute Layer

A containerized application layer running on ECS Fargate behind an Application Load Balancer:

- **ECS Cluster** with Container Insights enabled for detailed metrics
- **IAM Task Execution Role** scoped to ECR pulls, CloudWatch Logs, and Secrets Manager (least privilege)
- **CloudWatch Log Group** capturing all container stdout/stderr with 7-day retention
- **Application Load Balancer** in public subnets, multi-AZ, listening on HTTP/80
- **Target Group** with HTTP health checks, IP-based targets for Fargate compatibility
- **HTTP Listener** forwarding all traffic to the target group
- **ECS Task Definition** specifying nginx container, 256 CPU / 512 MB memory, awsvpc network mode
- **ECS Service** maintaining 2 tasks across both private subnets, registered to the target group

### Compute engineering decisions

- **Fargate over EC2 launch type.** No EC2 fleet to patch, scale, or manage. AWS handles the underlying compute. Tasks scale independently and are billed per-second.
- **awsvpc network mode.** Each task gets its own ENI with a private IP and its own security group attachments. This is what makes the per-task firewall chain (ALB SG → ECS SG → DB SG) actually enforceable. In `bridge` or `host` mode, all containers on a host share networking, breaking per-task isolation.
- **`assign_public_ip = false`.** Tasks live in private subnets with no public IPs. Outbound traffic goes through NAT; inbound is filtered by the ECS security group accepting only ALB traffic. Public IPs would be wasted (private subnet routes don't reach IGW anyway) and create misleading architecture signals.
- **Target group `name_prefix` + `lifecycle.create_before_destroy`.** Port changes on a target group force replacement, but a target group can't be destroyed while a listener references it. The combination enables zero-downtime replacement: new TG creates with a unique random name, listener swaps to it, old TG is then safely destroyed.
- **`container_insights = enabled` on the cluster.** Sends per-task CPU, memory, and network metrics to CloudWatch. Costs slightly more but enables real observability in Phase 5.
- **Health check threshold of 2.** More aggressive than the AWS defaults (5/2). Faster failure detection in development; production might use the gentler defaults to avoid flapping.
- **Container logs to CloudWatch with 7-day retention.** Cheap, auto-deleted, sufficient for development. Production would tier retention by log type — application logs at 30 days, audit logs at 90+, compliance logs forever.

### Engineering decisions worth noting

- **`for_each` over `count`** for all repeated resources to avoid index-shift problems
- **Dynamic CIDR computation** using `cidrsubnet()` so subnet allocation auto-adjusts when the VPC CIDR changes
- **`aws_availability_zones` data source** to make the code region-portable
- **`default_tags` at the provider level** to enforce consistent tagging across all resources
- **Tier-first CIDR allocation** (public 0.x, private 10.x, db 20.x) so any IP in a log immediately reveals which tier it belongs to


## Architecture

```
                              Internet
                                  │
                                  │
                          ┌───────▼────────┐
                          │ Internet GW    │
                          └───────┬────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  │                               │
        ╔═════════▼═══════════╗         ╔═════════▼═══════════╗
        ║   us-east-1a        ║         ║   us-east-1b        ║
        ║                     ║         ║                     ║
        ║  ┌───────────────┐  ║         ║  ┌───────────────┐  ║
        ║  │ Public Subnet │  ║         ║  │ Public Subnet │  ║
        ║  │ 10.0.0.0/24   │  ║         ║  │ 10.0.1.0/24   │  ║
        ║  │               │  ║         ║  │               │  ║
        ║  │   NAT GW      │  ║         ║  │               │  ║
        ║  └───────┬───────┘  ║         ║  └───────────────┘  ║
        ║          │          ║         ║                     ║
        ║  ┌───────▼───────┐  ║         ║  ┌───────────────┐  ║
        ║  │Private Subnet │  ║         ║  │Private Subnet │  ║
        ║  │ 10.0.10.0/24  │◄─╬─────────╬─►│ 10.0.11.0/24  │  ║
        ║  │ (ECS tasks)   │  ║         ║  │ (ECS tasks)   │  ║
        ║  └───────────────┘  ║         ║  └───────────────┘  ║
        ║                     ║         ║                     ║
        ║  ┌───────────────┐  ║         ║  ┌───────────────┐  ║
        ║  │  DB Subnet    │  ║         ║  │  DB Subnet    │  ║
        ║  │ 10.0.20.0/24  │  ║         ║  │ 10.0.21.0/24  │  ║
        ║  │  (no internet │  ║         ║  │  (no internet │  ║
        ║  │     route)    │  ║         ║  │     route)    │  ║
        ║  └───────────────┘  ║         ║  └───────────────┘  ║
        ╚═════════════════════╝         ╚═════════════════════╝

        VPC: 10.0.0.0/16
```

**Traffic flow:**

- **Inbound:** Internet → IGW → Public subnets (where the load balancer will live in Phase 2)
- **Outbound from private:** Private subnets → NAT Gateway (in public 1a) → IGW → Internet
- **Database isolation:** DB subnets have no `0.0.0.0/0` route — they cannot initiate connections to the internet, preventing data exfiltration if compromised

**Cost-vs-availability tradeoff:**  
Single NAT Gateway in `us-east-1a` chosen for cost (~$35/month savings vs. one per AZ). Production deployments would use one NAT per AZ to maintain AZ-level isolation.

## Project Structure

```
└── modules/
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── compute/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

The root module acts as an orchestrator — calling modules and wiring values between them. Each module is a self-contained unit with explicit inputs and outputs, making it reusable across projects.

## Tech Stack

- **AWS** — VPC, EC2 networking primitives, NAT Gateway, Elastic IP
- **Terraform** ≥ 1.5, AWS provider 5.x
- **Git Bash** on Windows for the development environment

## Roadmap

- **Phase 2:** ECS Fargate compute layer, Application Load Balancer, target groups ✅
- **Phase 3:** RDS PostgreSQL in private DB subnets with credentials in AWS Secrets Manager
- **Phase 4:** CI/CD with GitHub Actions and OIDC federation (no long-lived AWS keys)
- **Phase 5:** Observability — CloudWatch dashboards, alarms, container logs
- **Phase 6:** Documentation polish, architecture diagram, video walkthrough

## How to Reproduce

```bash
# Clone the repo
git clone https://github.com/Mallaimy/aws-cloudnative-webapp.git
cd aws-cloudnative-webapp

# Configure AWS credentials
aws configure

# Initialize and review
terraform init
terraform plan

# Apply (creates 19 resources)
terraform apply

# Destroy when done (avoid NAT Gateway charges)
terraform destroy
```

## Cost Considerations

This project includes resources that incur real AWS charges:
- **NAT Gateway:** ~$0.045/hour ($1.08/day)
- **Elastic IP:** ~$0.005/hour while allocated
- Other resources (VPC, subnets, IGW, route tables) are free

Recommended workflow during learning: `terraform destroy` between sessions, `terraform apply` when resuming. This costs near-zero and confirms the code is fully reproducible.

## Project Status

Active development. Built as part of a transition into Cloud/DevOps Engineering roles.

---

Built by [Abakar Mahamat Mallah](https://www.linkedin.com/in/abakar-mahamat-mallah-57b793218/) — AWS Solutions Architect Associate certified.