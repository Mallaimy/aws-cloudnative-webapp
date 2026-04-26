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
