# Architecture Overview

## High-Level Infrastructure

```mermaid
graph TB
    Internet((Internet / Users))

    subgraph CF_Path["App Updates Path (Optional)"]
        CF[CloudFront Distribution]
        S3_Updates[S3 Bucket<br/>App Update Artifacts]
    end

    subgraph API_Path["API Traffic Path"]
        WAF[AWS WAF v2<br/>Rate Limiting + Managed Rules]
        ALB[Application Load Balancer<br/>HTTP/HTTPS]
    end

    Internet --> CF
    Internet --> WAF
    WAF --> ALB
    CF -->|OAC| S3_Updates

    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph Public_Subnets["Public Subnets (2 AZs)"]
            ECS[ECS Fargate Cluster<br/>Container Port 8080]
            BTB_EC2[EC2 Instance<br/>btb-service<br/>Optional]
        end

        subgraph Private_Subnets["Database Subnets (2 AZs)"]
            RDS[(RDS PostgreSQL 15)]
            Redis[(ElastiCache Redis 7.0<br/>Optional)]
        end
    end

    ALB -->|Port 8080| ECS
    ECS --> RDS
    ECS --> Redis

    subgraph Supporting["Supporting Services"]
        ECR[ECR Repository]
        SM[Secrets Manager]
        CW[CloudWatch<br/>Logs + Alarms]
        S3_Logs[S3 Bucket<br/>ALB Access Logs]
    end

    ECS --> ECR
    ECS --> SM
    ECS --> CW
    ALB --> S3_Logs
    BTB_EC2 --> Bedrock[Amazon Bedrock]

    subgraph External["External APIs"]
        Supabase[Supabase]
        OpenAI[OpenAI]
        Stripe[Stripe]
        Gemini[Gemini]
        Brave[Brave Search]
    end

    ECS --> External

    subgraph CICD["CI/CD"]
        GH[GitHub Actions]
    end

    GH -->|OIDC| S3_Updates
    GH -->|Invalidate| CF
    GH -->|Push Image| ECR
```

## Network Architecture

```mermaid
graph TB
    IGW[Internet Gateway]

    subgraph VPC["VPC"]
        subgraph AZ1["Availability Zone 1"]
            Pub1[Public Subnet<br/>10.0.0.0/24]
            DB1[Database Subnet<br/>10.0.100.0/24]
        end

        subgraph AZ2["Availability Zone 2"]
            Pub2[Public Subnet<br/>10.0.1.0/24]
            DB2[Database Subnet<br/>10.0.101.0/24]
        end
    end

    IGW --> Pub1
    IGW --> Pub2

    Pub1 --- ALB_1[ALB]
    Pub2 --- ALB_1
    Pub1 --- ECS_1[ECS Tasks<br/>Public IPs]
    Pub2 --- ECS_1

    DB1 --- RDS_1[(RDS)]
    DB2 --- RDS_1
    DB1 --- Redis_1[(Redis)]
    DB2 --- Redis_1

    style DB1 fill:#f9e0e0
    style DB2 fill:#f9e0e0
    style Pub1 fill:#e0f0e0
    style Pub2 fill:#e0f0e0
```

## Security Groups

```mermaid
graph LR
    Internet((Internet)) -->|80, 443| SG_ALB[ALB SG]
    SG_ALB -->|8080| SG_ECS[ECS SG]
    SG_ECS -->|5432| SG_RDS[RDS SG]
    SG_ECS -->|6379| SG_Redis[Redis SG]
    SG_ECS -->|All Outbound| External((External APIs))

    SSH((Admin)) -->|22| SG_BTB[BTB EC2 SG]
    SSH -->|8443| SG_BTB
```

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant WAF
    participant ALB
    participant ECS as ECS Fargate
    participant RDS as PostgreSQL
    participant Redis
    participant SM as Secrets Manager
    participant APIs as External APIs

    User->>WAF: HTTPS Request
    WAF->>WAF: Rate limit + rule check
    WAF->>ALB: Forward (if allowed)
    ALB->>ECS: Route to container:8080
    ECS->>SM: Fetch secrets (on startup)
    ECS->>RDS: Database queries
    ECS->>Redis: Cache read/write
    ECS->>APIs: OpenAI / Stripe / Supabase
    ECS-->>ALB: Response
    ALB-->>User: Response
```

## App Updates Flow

```mermaid
sequenceDiagram
    participant Dev as GitHub Actions
    participant S3 as S3 Bucket
    participant CF as CloudFront
    participant App as Tauri Desktop App

    Dev->>Dev: Build release artifacts
    Dev->>S3: Upload artifacts (OIDC auth)
    Dev->>CF: Create cache invalidation
    App->>CF: GET latest.json
    CF->>S3: Fetch via OAC
    S3-->>CF: Return artifact
    CF-->>App: Serve update (60s cache TTL)
```

## Module Dependency Graph

```mermaid
graph TD
    VPC[modules/vpc] --> SG[modules/security-groups]
    VPC --> ALB_M[modules/alb]
    VPC --> ECS_M[modules/ecs]
    VPC --> RDS_M[modules/rds]
    VPC --> EC_M[modules/elasticache]
    VPC --> BTB[modules/btb-ec2]

    SG --> ALB_M
    SG --> ECS_M
    SG --> RDS_M
    SG --> EC_M
    SG --> BTB

    MON_PRE[modules/monitoring-prereq] --> ALB_M
    MON_PRE --> ECS_M

    RDS_M --> SEC[modules/secrets]
    EC_M --> SEC
    SEC --> ECS_M

    ECR_M[modules/ecr] --> ECS_M
    ALB_M --> ECS_M
    ALB_M --> WAF_M[modules/waf]
    ALB_M --> MON_A[modules/monitoring-alarms]
    ECS_M --> MON_A

    BTB_IAM[modules/btb-iam] --> BTB
    APP[modules/app-updates] -.->|Independent| VPC

    style APP fill:#ffe0b2
    style BTB fill:#ffe0b2
    style EC_M fill:#ffe0b2
```

> Orange modules are optional (controlled by feature flags).
