# ELK Stack Tutorial - Docker Setup Guide

## 🐳 Docker-Based ELK Stack

Setup lengkap ELK Stack menggunakan Docker Compose untuk kemudahan deployment dan pengembangan lokal.

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose installed
- Minimum 8GB RAM
- Minimum 20GB disk space

### Setup Commands
```bash
# Setup ELK Stack dengan Docker
./setup-docker.sh

# Uninstall bersih
./uninstall-docker.sh
```

## 🏗️ Architecture

```
Docker Network: elk-network
├── Elasticsearch (9200:9200)
├── Kibana (5601:5601)
├── Logstash (5044:5044, 9600:9600)
├── Kafka (29092:29092)
├── Zookeeper (2181)
├── Filebeat (log collector)
├── Sample Apps:
│   ├── Order Service (8080:80)
│   ├── Product Service (8081:80)
│   └── User Service (8082:80)
└── Monitoring:
    ├── Kafka UI (8090:8080)
    └── Elasticsearch Head (9100:9100)
```

## 📋 Services Overview

### Core ELK Stack
| Service | Port | Purpose |
|---------|------|---------|
| Elasticsearch | 9200 | Search and analytics engine |
| Kibana | 5601 | Data visualization dashboard |
| Logstash | 5044, 9600 | Log processing pipeline |
| Filebeat | - | Log collection agent |

### Streaming & Messaging
| Service | Port | Purpose |
|---------|------|---------|
| Kafka | 29092 | Message streaming platform |
| Zookeeper | 2181 | Kafka coordination service |

### Sample Applications
| Service | Port | Purpose |
|---------|------|---------|
| Order Service | 8080 | E-commerce order management |
| Product Service | 8081 | Product catalog service |
| User Service | 8082 | User management service |
| Log Generator | - | Automated log generation |

### Monitoring Tools
| Service | Port | Purpose |
|---------|------|---------|
| Kafka UI | 8090 | Kafka cluster monitoring |
| Elasticsearch Head | 9100 | Elasticsearch cluster monitoring |

## 🛠️ Setup Process

### 1. Prerequisites Check
```bash
# Automatic checks for:
- Docker installation
- Docker Compose availability
- Available disk space (min 10GB)
- Available memory (min 6GB)
- Docker daemon status
```

### 2. Environment Setup
```bash
# System optimization:
- Set vm.max_map_count=262144 for Elasticsearch
- Create required directories
- Set proper permissions
```

### 3. Configuration Files
```bash
# Auto-generated configs:
- Elasticsearch: cluster settings, security disabled
- Kibana: dashboard configuration
- Logstash: pipeline configurations
- Filebeat: log collection rules
- Nginx: sample application configs
```

### 4. Service Startup
```bash
# Staged startup:
1. Infrastructure (Zookeeper, Kafka, Elasticsearch)
2. Processing (Kibana, Logstash)
3. Collection (Filebeat)
4. Applications (Sample services)
5. Monitoring (Kafka UI, ES Head)
```

## 🔧 Configuration Details

### Elasticsearch Configuration
```yaml
cluster.name: elk-cluster
node.name: elasticsearch
discovery.type: single-node
xpack.security.enabled: false
bootstrap.memory_lock: true
```

### Kibana Configuration
```yaml
server.host: 0.0.0.0
elasticsearch.hosts: ["http://elasticsearch:9200"]
xpack.security.enabled: false
```

### Logstash Pipeline
```ruby
input {
  beats { port => 5044 }
  kafka {
    bootstrap_servers => "kafka:9092"
    topics => ["logs", "metrics", "events"]
  }
}

filter {
  # Log parsing and enrichment
  # Service identification
  # Log level classification
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
```

### Filebeat Configuration
```yaml
filebeat.inputs:
- type: log
  paths: ["/var/log/nginx/*.log"]
  fields:
    log_type: nginx
    service: web

- type: container
  paths: ["/var/lib/docker/containers/*/*.log"]
  processors:
    - add_docker_metadata

output.logstash:
  hosts: ["logstash:5044"]
```

## 🌐 Access URLs

### Main Services
- **Kibana Dashboard**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200
- **Logstash**: http://localhost:9600

### Sample Applications
- **Order Service**: http://localhost:8080
- **Product Service**: http://localhost:8081
- **User Service**: http://localhost:8082

### Monitoring
- **Kafka UI**: http://localhost:8090
- **Elasticsearch Head**: http://localhost:9100

## 💻 Usage Examples

### Basic Operations
```bash
# Start ELK Stack
./setup-docker.sh

# View logs
docker-compose logs -f elasticsearch
docker-compose logs -f kibana
docker-compose logs -f logstash

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Scale services
docker-compose up -d --scale logstash=3
```

### Testing & Validation
```bash
# Test Elasticsearch
curl -X GET "localhost:9200/_cluster/health?pretty"

# Test Kibana
curl -X GET "localhost:5601/api/status"

# Test Logstash
curl -X GET "localhost:9600/_node/stats"

# Test sample applications
curl -X GET "localhost:8080/api/orders"
curl -X GET "localhost:8081/api/products"
curl -X GET "localhost:8082/api/users"
```

### Index Management
```bash
# List indices
curl -X GET "localhost:9200/_cat/indices?v"

# Create index template
curl -X PUT "localhost:9200/_index_template/logs-template" \
  -H 'Content-Type: application/json' \
  -d @index-template.json

# Delete index
curl -X DELETE "localhost:9200/logs-2024.01.01"
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Elasticsearch Won't Start
```bash
# Check vm.max_map_count
sysctl vm.max_map_count

# Set if needed (requires root)
sudo sysctl -w vm.max_map_count=262144

# Check logs
docker-compose logs elasticsearch
```

#### 2. Low Memory Issues
```bash
# Reduce heap sizes in docker-compose.yml
environment:
  - "ES_JAVA_OPTS=-Xms1g -Xmx1g"  # Reduce from 2g
  - "LS_JAVA_OPTS=-Xms1g -Xms1g"  # Reduce from 2g
```

#### 3. Port Conflicts
```bash
# Check port usage
netstat -tlnp | grep :9200
netstat -tlnp | grep :5601

# Modify ports in docker-compose.yml
ports:
  - "9201:9200"  # Use different host port
```

#### 4. Permission Issues
```bash
# Fix log directory permissions
sudo chmod -R 755 logs/
sudo chown -R $USER:$USER logs/
```

#### 5. Service Dependencies
```bash
# Check service status
docker-compose ps

# Restart specific service
docker-compose restart elasticsearch

# View service health
docker-compose logs --tail=50 elasticsearch
```

## 🔄 Maintenance

### Regular Tasks
```bash
# Update images
docker-compose pull

# Restart services
docker-compose restart

# Clean up system
docker system prune -f

# Backup data
docker run --rm -v elk-tutorial_elasticsearch_data:/data -v $(pwd):/backup alpine tar czf /backup/elasticsearch-backup.tar.gz /data
```

### Monitoring
```bash
# Check resource usage
docker stats

# Check disk usage
docker system df

# Check container health
docker-compose ps
```

## 🚨 Uninstall & Cleanup

### Complete Removal
```bash
# Stop and remove everything
./uninstall-docker.sh

# Manual cleanup if needed
docker-compose down -v
docker system prune -af
```

### Selective Cleanup
```bash
# Remove only volumes
docker-compose down -v

# Remove only containers
docker-compose down

# Remove specific service
docker-compose rm -s -v elasticsearch
```

## 📊 Performance Tuning

### Elasticsearch Optimization
```yaml
environment:
  - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
  - bootstrap.memory_lock=true
  - indices.memory.index_buffer_size=30%
```

### Logstash Optimization
```yaml
environment:
  - "LS_JAVA_OPTS=-Xms2g -Xmx2g"
  - pipeline.workers=4
  - pipeline.batch.size=1000
```

### Kafka Optimization
```yaml
environment:
  - KAFKA_NUM_PARTITIONS=3
  - KAFKA_DEFAULT_REPLICATION_FACTOR=1
  - KAFKA_LOG_RETENTION_HOURS=24
```

## 🎯 Next Steps

1. **Explore Kibana**: Create dashboards and visualizations
2. **Test Applications**: Generate logs through sample apps
3. **Monitor Performance**: Use Kafka UI and ES Head
4. **Customize Configuration**: Modify pipelines and mappings
5. **Scale Services**: Add more Logstash or Elasticsearch nodes

## 📞 Support

For issues or questions:
1. Check logs: `docker-compose logs <service>`
2. Verify configuration files
3. Test connectivity between services
4. Check system resources
5. Consult official documentation

---

**📦 Docker-based ELK Stack - Ready for Development and Testing! 🚀**
