# Kafka Configuration for ELK Stack

## Overview
Kafka berfungsi sebagai message broker yang reliable antara Beats dan Logstash. Dalam arsitektur enterprise, Kafka memberikan:

### Key Benefits:
1. **Decoupling**: Memisahkan log producers (Beats) dari consumers (Logstash)
2. **Scalability**: Horizontal scaling dengan partitions
3. **Reliability**: Data persistence dan replication
4. **High Throughput**: Dapat handle millions of messages per second
5. **Backpressure Handling**: Buffer untuk mengatasi spike dalam log volume

## Real Use Case: E-commerce Log Processing

### Scenario:
Perusahaan e-commerce dengan:
- **50+ microservices** running in OpenShift
- **10,000+ transactions per minute** during peak hours
- **Black Friday/Cyber Monday** dengan 10x traffic normal
- **Multi-region deployment** (US, EU, APAC)
- **Compliance requirements** (GDPR, PCI-DSS)

### Log Volume Estimation:
- **Normal load**: 1GB logs per hour
- **Peak load**: 10GB logs per hour
- **Total daily**: 100GB+ logs
- **Retention**: 30 days hot, 365 days cold storage

## Kafka Topics Strategy

### 1. Environment-based Topics
```
logs.production.applications
logs.production.infrastructure
logs.production.security
logs.production.business
logs.staging.applications
logs.development.applications
```

### 2. Service-based Topics
```
logs.production.order-service
logs.production.payment-service
logs.production.user-service
logs.production.notification-service
```

### 3. Log Level Topics
```
logs.production.error
logs.production.warn
logs.production.info
logs.production.debug
```

## Partitioning Strategy

### Business-driven Partitioning:
- **Partition by Service**: Each microservice gets dedicated partitions
- **Partition by Region**: Geographic distribution for compliance
- **Partition by Criticality**: High-priority services get more partitions

### Example Configuration:
```yaml
topics:
  logs.production.payment-service:
    partitions: 6  # High throughput, critical service
    replication-factor: 3
    
  logs.production.order-service:
    partitions: 4  # High volume
    replication-factor: 3
    
  logs.production.user-service:
    partitions: 2  # Medium volume
    replication-factor: 3
```

## Data Retention Policy

### Hot Data (Fast Access):
- **Retention**: 7 days
- **Storage**: SSD-based storage
- **Use case**: Real-time monitoring, alerting, debugging

### Warm Data (Regular Access):
- **Retention**: 30 days
- **Storage**: Standard storage
- **Use case**: Weekly reports, trend analysis

### Cold Data (Archive):
- **Retention**: 365 days
- **Storage**: Object storage (S3)
- **Use case**: Compliance, audit, long-term analysis

## Security Implementation

### 1. Authentication & Authorization
- **SASL/SCRAM**: User authentication
- **ACLs**: Topic-level permissions
- **mTLS**: Certificate-based authentication

### 2. Encryption
- **In-transit**: TLS 1.3 encryption
- **At-rest**: Disk encryption
- **End-to-end**: Application-level encryption for sensitive data

### 3. Network Security
- **VPC**: Private networking
- **Firewall**: Restrict access to Kafka ports
- **Monitoring**: Connection and access logging

## Performance Tuning

### Producer Settings (Beats):
```yaml
producer:
  acks: 1                    # Balance between performance and durability
  retries: 3                 # Retry failed sends
  batch.size: 16384         # Batch size in bytes
  linger.ms: 5              # Wait time to batch messages
  compression.type: gzip    # Compress messages
  max.in.flight.requests.per.connection: 5
```

### Consumer Settings (Logstash):
```yaml
consumer:
  fetch.min.bytes: 1024     # Minimum bytes to fetch
  fetch.max.wait.ms: 500    # Maximum wait time
  max.partition.fetch.bytes: 1048576  # 1MB max per partition
  auto.offset.reset: earliest
  enable.auto.commit: false  # Manual commit for reliability
```

## Monitoring & Alerting

### Key Metrics to Monitor:
1. **Throughput**: Messages per second in/out
2. **Latency**: End-to-end message latency
3. **Consumer Lag**: How far behind consumers are
4. **Disk Usage**: Storage utilization per topic
5. **Network I/O**: Bandwidth utilization

### Critical Alerts:
- Consumer lag > 10,000 messages
- Disk usage > 80%
- Broker downtime
- Replication factor violations
- Authentication failures

## Disaster Recovery

### Backup Strategy:
1. **Cross-region replication** for critical topics
2. **Automated snapshots** of Kafka state
3. **Configuration backup** in version control
4. **Recovery procedures** documented and tested

### RTO/RPO Targets:
- **RTO**: 15 minutes for critical services
- **RPO**: 1 minute data loss maximum
- **Testing**: Monthly DR drills

## Next Steps:
- [Kafka Cluster Setup](./cluster-setup/)
- [Topic Management](./topics/)
- [Security Configuration](./security/)
- [Monitoring Setup](./monitoring/)
