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
## Architecture

\`\`\`mermaid
graph TB
    Internet((Internet))
    
    subgraph VPC["VPC 10.0.0.0/16"]
        IGW[Internet Gateway]
        
        subgraph AZ1["Availability Zone us-east-1a"]
            PubA["Public Subnet<br/>10.0.0.0/24"]
            PrivA["Private Subnet<br/>10.0.10.0/24"]
            DbA["DB Subnet<br/>10.0.20.0/24"]
            NAT[NAT Gateway]
        end
        
        subgraph AZ2["Availability Zone us-east-1b"]
            PubB["Public Subnet<br/>10.0.1.0/24"]
            PrivB["Private Subnet<br/>10.0.11.0/24"]
            DbB["DB Subnet<br/>10.0.21.0/24"]
        end
    end
    
    Internet <--> IGW
    IGW <--> PubA
    IGW <--> PubB
    PubA --> NAT
    NAT --> PrivA
    NAT --> PrivB
    
    classDef public fill:#90EE90,stroke:#333,color:#000
    classDef private fill:#FFD700,stroke:#333,color:#000
    classDef db fill:#FFB6C1,stroke:#333,color:#000
    
    class PubA,PubB public
    class PrivA,PrivB private
    class DbA,DbB db
\`\`\`

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