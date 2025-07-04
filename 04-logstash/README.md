# Logstash Configuration for ELK Stack

## Overview
Logstash adalah data processing pipeline yang menerima data dari Kafka, melakukan transformasi, parsing, dan enrichment, kemudian mengirimnya ke Elasticsearch.

## Real Use Case: E-commerce Log Processing Pipeline

### Business Requirements:
1. **Real-time Processing**: Process 100,000+ log events per minute
2. **Data Enrichment**: Add business context to raw logs
3. **Format Standardization**: Convert various log formats to ECS (Elastic Common Schema)
4. **Security**: Mask sensitive information (PII, payment data)
5. **Routing**: Send different log types to appropriate Elasticsearch indices
6. **Alerting**: Trigger alerts for critical errors and security events

## Processing Pipeline Architecture

```
Kafka Topics → Logstash Input → Filters & Processors → Elasticsearch Output
                    ↓
            [Grok Parsing]
                    ↓
            [JSON Parsing]
                    ↓
            [Field Enrichment]
                    ↓
            [Data Masking]
                    ↓
            [GeoIP Enhancement]
                    ↓
            [Business Logic]
                    ↓
            [Index Routing]
```

## Key Processing Features

### 1. Multi-Pipeline Architecture
- **Application Logs Pipeline**: Standard application logs
- **Security Logs Pipeline**: Authentication, authorization events
- **Business Events Pipeline**: Transaction logs, user behavior
- **Infrastructure Pipeline**: System metrics, container logs

### 2. Advanced Parsing
- **Grok Patterns**: Parse unstructured logs
- **JSON Parsing**: Handle structured logs
- **CSV Parsing**: Process batch imports
- **XML Parsing**: Legacy system integration

### 3. Data Enrichment
- **GeoIP**: Add geographic information
- **User Agent**: Parse browser/device information
- **Business Data**: Add customer segments, product categories
- **Threat Intelligence**: Security event enrichment

### 4. Performance Optimization
- **Parallel Processing**: Multiple worker threads
- **Batching**: Process events in batches
- **Persistent Queues**: Handle backpressure
- **Dead Letter Queues**: Handle processing failures

## Real-World Processing Examples

### 1. E-commerce Transaction Processing
```ruby
# Input: Raw payment log
{
  "timestamp": "2025-06-28T10:30:00.000Z",
  "service": "payment-service",
  "message": "Payment processed successfully",
  "amount": 299.99,
  "currency": "USD",
  "payment_method": "credit_card",
  "card_last_four": "1234",
  "user_id": "user_98765"
}

# Output: Enriched business event
{
  "@timestamp": "2025-06-28T10:30:00.000Z",
  "service": {
    "name": "payment-service",
    "version": "1.2.3",
    "environment": "production"
  },
  "event": {
    "category": "business",
    "type": "transaction",
    "outcome": "success"
  },
  "transaction": {
    "id": "txn_abc123",
    "amount": 299.99,
    "currency": "USD",
    "type": "payment"
  },
  "payment": {
    "method": "credit_card",
    "processor": "stripe",
    "card_type": "visa",
    "masked_card": "****-****-****-1234"
  },
  "user": {
    "id": "user_98765",
    "segment": "premium",
    "country": "US"
  },
  "business": {
    "revenue_impact": 299.99,
    "category": "electronics",
    "profit_margin": 0.25
  }
}
```

### 2. Security Event Processing
```ruby
# Input: Authentication failure
{
  "timestamp": "2025-06-28T10:31:00.000Z",
  "service": "auth-service",
  "level": "WARN",
  "message": "Login failed for user",
  "user_email": "suspicious@evil.com",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}

# Output: Security alert
{
  "@timestamp": "2025-06-28T10:31:00.000Z",
  "event": {
    "category": "security",
    "type": "authentication",
    "outcome": "failure"
  },
  "user": {
    "email": "sus***@***.com",  # Masked for privacy
    "risk_score": 85
  },
  "source": {
    "ip": "192.168.1.100",
    "geo": {
      "country": "US",
      "city": "New York",
      "coordinates": [40.7589, -73.9851]
    }
  },
  "threat": {
    "indicator": "known_bad_ip",
    "confidence": "high",
    "feed": "threat_intelligence"
  },
  "alert": {
    "severity": "medium",
    "rule": "multiple_failed_logins",
    "action": "block_ip"
  }
}
```

## Performance Metrics & Monitoring

### Key Performance Indicators:
1. **Throughput**: Events processed per second
2. **Latency**: End-to-end processing time
3. **Error Rate**: Failed processing percentage
4. **Queue Depth**: Pending events in pipeline
5. **Resource Usage**: CPU, memory, disk utilization

### Real-Time Monitoring:
- **Dashboard**: Grafana dashboard with real-time metrics
- **Alerting**: PagerDuty integration for critical issues
- **Health Checks**: Regular pipeline health monitoring
- **Capacity Planning**: Predictive scaling based on patterns

## Error Handling & Reliability

### Dead Letter Queue Strategy:
```ruby
# Events yang gagal diproses dikirim ke DLQ
if processing_failed {
  send_to_dead_letter_queue(event)
  log_error(event, error_details)
  increment_error_counter()
}
```

### Retry Mechanisms:
- **Exponential Backoff**: Retry dengan delay yang meningkat
- **Circuit Breaker**: Stop processing jika error rate tinggi
- **Graceful Degradation**: Partial processing jika sebagian pipeline gagal

## Security & Compliance

### Data Protection:
1. **PII Masking**: Automatic detection and masking
2. **Encryption**: TLS for all communications
3. **Access Control**: RBAC untuk pipeline management
4. **Audit Logging**: Log semua administrative actions

### Compliance Features:
- **GDPR**: Right to be forgotten implementation
- **PCI-DSS**: Payment data protection
- **SOX**: Financial transaction audit trails
- **HIPAA**: Healthcare data protection (if applicable)

## Scalability & High Availability

### Horizontal Scaling:
- **Multiple Instances**: Run multiple Logstash instances
- **Load Balancing**: Distribute load across instances
- **Auto-scaling**: Scale based on queue depth

### High Availability:
- **Multi-AZ Deployment**: Instances across availability zones
- **Health Monitoring**: Automatic failover
- **Data Persistence**: Ensure no data loss during failures

## Next Steps:
- [Pipeline Configuration](./pipelines/)
- [Custom Filters](./filters/)
- [Monitoring Setup](./monitoring/)
- [Performance Tuning](./performance/)
