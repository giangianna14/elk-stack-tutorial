# Beats Configuration for OpenShift

## Overview
Beats adalah lightweight data shippers yang akan mengumpulkan logs dan metrics dari aplikasi di OpenShift dan mengirimkannya ke Kafka.

## Filebeat Configuration

Filebeat akan berjalan sebagai DaemonSet di setiap node OpenShift untuk mengumpulkan logs dari semua containers.

### Real Use Case: Multi-Tenant Log Collection
- **Production Environment**: Mengumpulkan logs dari 50+ microservices
- **Development Environment**: Debugging dan development logs
- **Security Events**: Authentication failures, suspicious activities
- **Business Events**: Transaction logs, user behavior

## Key Features yang akan dikonfigurasi:

### 1. Autodiscovery
Filebeat akan secara otomatis menemukan containers baru dan mulai mengumpulkan logs berdasarkan annotations.

### 2. Multiline Processing
Menggabungkan stack traces dan multi-line logs menjadi single events.

### 3. Field Enrichment
Menambahkan metadata Kubernetes seperti namespace, pod name, labels.

### 4. Filtering & Parsing
Memproses JSON logs dan menambahkan structured fields.

### 5. Output ke Kafka
Mengirim logs ke Kafka topics yang berbeda berdasarkan service atau environment.

## Log Processing Flow

```
Container Logs → Filebeat → JSON Parsing → Field Enrichment → Kafka Topics
```

### Kafka Topic Strategy:
- `logs.production.applications` - Production application logs
- `logs.production.infrastructure` - Infrastructure logs
- `logs.production.security` - Security events
- `logs.production.business` - Business metrics/events
- `logs.development.*` - Development environment logs

## Metricbeat Configuration

Metricbeat akan mengumpulkan metrics dari:

### 1. System Metrics
- CPU, Memory, Disk, Network usage
- Process-level metrics

### 2. Kubernetes Metrics
- Pod metrics, Node metrics
- Container resource usage

### 3. Application Metrics
- Custom application metrics via Prometheus endpoints
- JVM metrics untuk Java applications

### 4. Business Metrics
- Orders per minute
- Revenue metrics
- User registration rates
- Error rates by service

## Benefits dari Beats dalam OpenShift:

1. **Low Resource Footprint**: Minimal impact pada aplikasi
2. **Native Kubernetes Integration**: Auto-discovery dan metadata enrichment
3. **Reliable Delivery**: Built-in retry mechanisms
4. **Security**: TLS encryption dan authentication
5. **Scalability**: Horizontal scaling dengan multiple instances

## Performance Considerations:

- **Batching**: Mengirim data dalam batches untuk efisiensi
- **Compression**: GZIP compression untuk mengurangi network overhead
- **Back-pressure Handling**: Graceful handling ketika Kafka tidak available
- **Memory Management**: Proper buffer management untuk high-volume logs

## Next Steps:
- [Filebeat DaemonSet Configuration](./filebeat-daemonset.yaml)
- [Metricbeat Deployment](./metricbeat-deployment.yaml)
- [Custom Processors](./processors/)
