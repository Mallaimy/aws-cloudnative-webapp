# AWS Cloud-Native Web Application

A production-style multi-AZ AWS architecture built with Terraform, designed to demonstrate real-world DevOps and cloud engineering practices for portfolio purposes.

## Current State — Phase 1: Networking Foundation ✅

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
aws-cloudnative-webapp/
├── main.tf              # Root: module orchestration
├── variables.tf         # Root variables (project-wide)
├── outputs.tf           # Root outputs (CLI access)
├── providers.tf         # AWS provider configuration
├── terraform.tfvars     # Variable values
└── modules/
    └── networking/
        ├── main.tf      # VPC, subnets, IGW, NAT, route tables
        ├── variables.tf # Module inputs (project_name, vpc_cidr, az_count)
        └── outputs.tf   # Module outputs (vpc_id, subnet_ids, etc.)
```

The root module acts as an orchestrator — calling modules and wiring values between them. Each module is a self-contained unit with explicit inputs and outputs, making it reusable across projects.

## Tech Stack

- **AWS** — VPC, EC2 networking primitives, NAT Gateway, Elastic IP
- **Terraform** ≥ 1.5, AWS provider 5.x
- **Git Bash** on Windows for the development environment

## Roadmap

- **Phase 2:** Refactor into reusable modules, add security groups, ECS Fargate, Application Load Balancer
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