# 🚀 ELK Stack Quick Reference

Referensi cepat untuk command dan operasi yang paling sering digunakan.

## 📋 Setup Commands

```bash
# Docker Setup (Recommended)
./setup-docker.sh

# Kubernetes Setup
./setup.sh

# Local Cluster Setup
./setup-local-cluster.sh

# Lightweight Setup
./setup-lightweight.sh

# Validate Setup
./test-scripts.sh
```

## 🔍 Service Health Checks

```bash
# Check all services
docker-compose ps

# Elasticsearch health
curl localhost:9200/_cluster/health?pretty

# Kibana status
curl localhost:5601/api/status

# Test sample apps
curl localhost:8080/orders
curl localhost:8081/products
curl localhost:8082/users
```

## 📊 Elasticsearch Commands

### Basic Operations
```bash
# List all indices
curl localhost:9200/_cat/indices?v

# Count documents
curl localhost:9200/_cat/count/logstash-*

# Get mapping
curl localhost:9200/logstash-*/_mapping?pretty

# Delete index
curl -X DELETE localhost:9200/logstash-2024.01.01
```

### Search Queries
```bash
# Search all documents
curl localhost:9200/logstash-*/_search?pretty

# Search with query
curl -X GET localhost:9200/logstash-*/_search?pretty -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "service.name": "order-service"
    }
  }
}'

# Aggregation query
curl -X GET localhost:9200/logstash-*/_search?pretty -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "services": {
      "terms": {
        "field": "service.name.keyword"
      }
    }
  }
}'
```

## 🛠️ Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart elasticsearch

# View logs
docker-compose logs -f kibana

# Check resource usage
docker stats

# Clean up
docker-compose down -v
docker system prune -f
```

## 🔧 Kibana Operations

### Index Patterns
1. Management → Index Patterns
2. Create pattern: `logstash-*`
3. Select timestamp: `@timestamp`

### Common Searches
```
# Search by service
service.name: "order-service"

# Search by log level
log.level: "ERROR"

# Search by time range
@timestamp: [now-1h TO now]

# Search by response time
response_time: >1000
```

## 📈 Monitoring Commands

```bash
# Generate sample data
for i in {1..10}; do
    curl -s localhost:8080/orders > /dev/null
    curl -s localhost:8081/products > /dev/null
    curl -s localhost:8082/users > /dev/null
    sleep 1
done

# Monitor log generation
watch -n 2 "curl -s localhost:9200/_cat/count/logstash-*"

# Check disk usage
df -h

# Check memory usage
free -h
```

## 🚨 Troubleshooting

### Common Issues
```bash
# Elasticsearch won't start
sudo sysctl -w vm.max_map_count=262144

# No data in Kibana
curl localhost:9200/_cat/indices?v
docker-compose logs filebeat

# High memory usage
docker stats
# Edit docker-compose.yml memory limits

# Port conflicts
netstat -tulpn | grep :9200
```

### Diagnostic Commands
```bash
# Complete health check
./test-scripts.sh

# Check all endpoints
curl -s localhost:9200/_cluster/health | jq '.status'
curl -s localhost:5601/api/status | jq '.status.overall.state'

# Check data flow
curl localhost:9200/_cat/indices?v | grep logstash
```

## 🧹 Cleanup Commands

```bash
# Stop and remove containers
docker-compose down

# Remove with volumes
docker-compose down -v

# Complete cleanup
./uninstall-docker.sh

# System cleanup
docker system prune -a -f
```

## 🔐 Security Commands

```bash
# Enable security (requires restart)
# Edit docker-compose.yml:
# - xpack.security.enabled=true
# - ELASTIC_PASSWORD=yourpassword

# Create user
curl -X POST localhost:9200/_security/user/analyst -H 'Content-Type: application/json' -d'
{
  "password": "password123",
  "roles": ["kibana_user", "monitoring_user"]
}'

# Test authentication
curl -u elastic:yourpassword localhost:9200/_cluster/health
```

## 📊 Performance Tuning

```bash
# Check performance
curl localhost:9200/_nodes/stats/indices/search?pretty

# Optimize indices
curl -X POST localhost:9200/logstash-*/_forcemerge?max_num_segments=1

# Clear cache
curl -X POST localhost:9200/_cache/clear
```

## 🎯 Quick Testing

```bash
# Test complete workflow
echo "=== Quick Test ==="

# 1. Generate data
curl localhost:8080/orders

# 2. Check in Elasticsearch
curl localhost:9200/logstash-*/_search?size=1&pretty

# 3. View in Kibana
echo "Check http://localhost:5601/app/discover"

# 4. Test aggregation
curl -X GET localhost:9200/logstash-*/_search?pretty -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "log_levels": {
      "terms": {
        "field": "log.level.keyword"
      }
    }
  }
}'
```

## 🔄 Regular Maintenance

```bash
# Daily checks
./test-scripts.sh
docker-compose ps
curl localhost:9200/_cluster/health

# Weekly maintenance
docker-compose logs --tail=100 > weekly-logs.txt
docker system prune -f

# Monthly cleanup
# Review and delete old indices
curl localhost:9200/_cat/indices?v
curl -X DELETE localhost:9200/logstash-2024.01.*
```

## 📱 Quick URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Kibana | http://localhost:5601 | Main dashboard |
| Elasticsearch | http://localhost:9200 | API endpoint |
| Kafka UI | http://localhost:8090 | Kafka monitoring |
| Order Service | http://localhost:8080 | Sample app |
| Product Service | http://localhost:8081 | Sample app |
| User Service | http://localhost:8082 | Sample app |

## 🆘 Emergency Commands

```bash
# Emergency stop
docker-compose down

# Emergency restart
docker-compose restart

# Emergency logs
docker-compose logs --tail=50

# Emergency cleanup
docker-compose down -v
docker system prune -a -f
./setup-docker.sh
```

---

💡 **Pro Tip**: Bookmark this page and use it as your daily reference for ELK Stack operations!
