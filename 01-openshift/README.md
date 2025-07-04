# OpenShift Application Setup

## Overview
Dalam section ini, kita akan mempelajari cara mendeploy aplikasi di OpenShift yang akan menghasilkan logs dan metrics untuk di-monitor menggunakan ELK stack.

## Real Use Case: E-commerce Microservices

Kita akan menggunakan contoh aplikasi e-commerce dengan arsitektur microservices:

### Services yang akan di-deploy:
1. **Frontend Service** - React.js application
2. **User Service** - Authentication & user management
3. **Product Service** - Product catalog management
4. **Order Service** - Order processing
5. **Payment Service** - Payment processing
6. **Notification Service** - Email/SMS notifications

## Deployment Architecture

```yaml
# OpenShift Project Structure
project: ecommerce-prod
├── frontend-service
├── user-service
├── product-service
├── order-service
├── payment-service
└── notification-service
```

## Logging Strategy

### 1. Application Logs
- **Access Logs**: HTTP requests/responses
- **Error Logs**: Application errors and exceptions
- **Business Logs**: Transaction logs, user activities
- **Security Logs**: Authentication attempts, authorization failures

### 2. Infrastructure Logs
- **Container Logs**: Pod lifecycle events
- **Node Logs**: System-level events
- **Network Logs**: Service mesh communication

### 3. Metrics Collection
- **Application Metrics**: Response time, throughput, error rates
- **Business Metrics**: Orders per minute, revenue, user registrations
- **Infrastructure Metrics**: CPU, memory, disk usage

## Log Format Standardization

Semua aplikasi akan menggunakan structured logging dengan format JSON:

```json
{
  "@timestamp": "2025-06-28T10:30:00.000Z",
  "level": "INFO",
  "service": "order-service",
  "version": "1.2.3",
  "trace_id": "abc123def456",
  "span_id": "789xyz012",
  "user_id": "user_12345",
  "session_id": "session_67890",
  "message": "Order created successfully",
  "order_id": "order_99999",
  "amount": 150.75,
  "currency": "USD",
  "payment_method": "credit_card",
  "environment": "production",
  "kubernetes": {
    "namespace": "ecommerce-prod",
    "pod": "order-service-7d4b8c9f-x2k8l",
    "container": "order-service"
  }
}
```

## Benefits dari Structured Logging

1. **Easy Parsing**: Logstash dapat dengan mudah mem-parse JSON
2. **Consistent Fields**: Field yang sama di semua services
3. **Rich Context**: Trace ID untuk distributed tracing
4. **Business Intelligence**: Metrics business embedded dalam logs

## Next Steps
- [Deploy Sample Applications](./sample-apps/)
- [Configure Logging](./logging-config/)
- [Setup Monitoring](./monitoring/)
