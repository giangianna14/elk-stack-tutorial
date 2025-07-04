# 🚀 ELK Stack Complete Hands-On Guide

Tutorial lengkap hands-on penggunaan ELK Stack dari awal sampai akhir dengan contoh praktis dan real-world scenarios.

## 📋 Table of Contents

1. [🏁 Getting Started](#-getting-started)
2. [🛠️ Setup Environment](#-setup-environment)
3. [📊 First Steps with Kibana](#-first-steps-with-kibana)
4. [🔍 Elasticsearch Basics](#-elasticsearch-basics)
5. [⚙️ Logstash Configuration](#-logstash-configuration)
6. [📈 Creating Dashboards](#-creating-dashboards)
7. [🔧 Advanced Configuration](#-advanced-configuration)
8. [🛡️ Security Setup](#-security-setup)
9. [📱 Real-World Scenarios](#-real-world-scenarios)
10. [🚨 Monitoring & Alerts](#-monitoring--alerts)
11. [🔄 Troubleshooting](#-troubleshooting)
12. [🎯 Best Practices](#-best-practices)

---

## 🏁 Getting Started

### Prerequisites Check
```bash
# Check system requirements
echo "=== System Requirements Check ==="
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo "Available RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Available Disk: $(df -h . | tail -1 | awk '{print $4}')"
echo "CPU Cores: $(nproc)"
```

### Download Tutorial
```bash
# Clone the tutorial repository
git clone https://github.com/giangianna14/elk-stack-tutorial.git
cd elk-stack-tutorial

# Make scripts executable
chmod +x *.sh

# Validate setup
./test-scripts.sh
```

---

## 🛠️ Setup Environment

### Step 1: Docker Setup (Recommended)
```bash
# Start the complete ELK Stack
./setup-docker.sh

# Wait for services to start (5-10 minutes)
echo "Waiting for services to start..."
sleep 60

# Check service status
docker-compose ps
```

**Expected Output:**
```
Name                    Command               State                    Ports
elk-elasticsearch    /bin/tini -- /usr/local/bin/  Up      0.0.0.0:9200->9200/tcp
elk-kibana           /bin/tini -- /usr/local/bin/  Up      0.0.0.0:5601->5601/tcp
elk-logstash         /usr/local/bin/docker-ent...  Up      0.0.0.0:5044->5044/tcp
elk-kafka            start-kafka.sh                Up      0.0.0.0:29092->29092/tcp
elk-filebeat         /usr/local/bin/docker-ent...  Up
elk-order-service    nginx -g daemon off;          Up      0.0.0.0:8080->80/tcp
elk-product-service  nginx -g daemon off;          Up      0.0.0.0:8081->80/tcp
elk-user-service     nginx -g daemon off;          Up      0.0.0.0:8082->80/tcp
```

### Step 2: Verify Services
```bash
# Test Elasticsearch
curl -X GET "localhost:9200/_cluster/health?pretty"

# Test Kibana
curl -X GET "localhost:5601/api/status"

# Test sample applications
curl http://localhost:8080/orders
curl http://localhost:8081/products
curl http://localhost:8082/users
```

**Expected Elasticsearch Response:**
```json
{
  "cluster_name" : "docker-cluster",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 1,
  "active_shards" : 1,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 1,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 50.0
}
```

---

## 📊 First Steps with Kibana

### Step 1: Access Kibana
1. Open browser: http://localhost:5601
2. Wait for Kibana to load (may take 1-2 minutes)

### Step 2: Create Index Pattern
1. Go to **Management** → **Stack Management**
2. Click **Index Patterns** under Kibana
3. Click **Create index pattern**
4. Enter pattern: `logstash-*`
5. Click **Next step**
6. Select **@timestamp** as time field
7. Click **Create index pattern**

### Step 3: Generate Sample Data
```bash
# Generate logs from sample applications
for i in {1..10}; do
    curl -s http://localhost:8080/orders > /dev/null
    curl -s http://localhost:8081/products > /dev/null
    curl -s http://localhost:8082/users > /dev/null
    sleep 2
done

# Check if data is flowing
curl "localhost:9200/_cat/indices?v"
```

### Step 4: Explore Data
1. Go to **Discover** in Kibana
2. Select your `logstash-*` index pattern
3. You should see logs flowing in
4. Try filtering by service: `service.name: "order-service"`

---

## 🔍 Elasticsearch Basics

### Understanding Indices
```bash
# List all indices
curl "localhost:9200/_cat/indices?v"

# Get index mapping
curl "localhost:9200/logstash-*/_mapping?pretty"

# Search for specific data
curl -X GET "localhost:9200/logstash-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "service.name": "order-service"
    }
  }
}
'
```

### Basic Queries
```bash
# Get all documents
curl -X GET "localhost:9200/logstash-*/_search?pretty&size=5"

# Search with time range
curl -X GET "localhost:9200/logstash-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-1h",
        "lte": "now"
      }
    }
  }
}
'

# Aggregation query
curl -X GET "localhost:9200/logstash-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "services": {
      "terms": {
        "field": "service.name.keyword"
      }
    }
  }
}
'
```

---

## ⚙️ Logstash Configuration

### Understanding Pipeline
```bash
# View current Logstash configuration
docker-compose exec logstash cat /usr/share/logstash/pipeline/applications.conf
```

### Custom Configuration
Let's create a custom pipeline for business events:

```bash
# Create custom pipeline
cat > custom-business.conf << 'EOF'
input {
  beats {
    port => 5045
  }
}

filter {
  if [service][name] == "order-service" {
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:msg}" }
    }
    
    if [msg] =~ /ORDER_CREATED/ {
      mutate {
        add_field => { "event_type" => "order_creation" }
        add_field => { "business_impact" => "high" }
      }
    }
    
    if [msg] =~ /PAYMENT_PROCESSED/ {
      mutate {
        add_field => { "event_type" => "payment" }
        add_field => { "business_impact" => "critical" }
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "business-events-%{+YYYY.MM.dd}"
  }
}
EOF

# Apply configuration (requires restart)
docker-compose restart logstash
```

---

## 📈 Creating Dashboards

### Step 1: Create Visualizations

#### 1. Service Request Count
1. Go to **Visualize** → **Create visualization**
2. Select **Vertical Bar Chart**
3. Select `logstash-*` index
4. **Y-axis**: Count
5. **X-axis**: Terms aggregation on `service.name.keyword`
6. Save as "Service Request Count"

#### 2. Response Time Over Time
1. Create **Line Chart**
2. **Y-axis**: Average of `response_time`
3. **X-axis**: Date Histogram on `@timestamp`
4. **Split Series**: Terms on `service.name.keyword`
5. Save as "Response Time Trend"

#### 3. Error Rate Gauge
1. Create **Gauge**
2. **Metric**: Count
3. **Bucket**: Filters
   - Filter 1: `log.level: "ERROR"`
   - Filter 2: `*` (all logs)
4. Save as "Error Rate"

### Step 2: Create Dashboard
1. Go to **Dashboard** → **Create dashboard**
2. Add all three visualizations
3. Arrange and resize as needed
4. Save as "E-commerce Monitoring"

### Step 3: Advanced Dashboard with Markdown
```markdown
# E-commerce Platform Dashboard

## Key Metrics
- **Total Orders**: Real-time order processing
- **Response Time**: API performance monitoring
- **Error Rate**: System health indicator

## Business Impact
- Order processing efficiency
- Customer experience metrics
- Revenue tracking
```

---

## 🔧 Advanced Configuration

### Data Transformation
```bash
# Create advanced Logstash configuration
cat > advanced-pipeline.conf << 'EOF'
input {
  beats {
    port => 5044
  }
}

filter {
  # Parse JSON logs
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
    }
  }
  
  # Add GeoIP information
  if [client_ip] {
    geoip {
      source => "client_ip"
      target => "geoip"
    }
  }
  
  # Calculate processing time
  if [start_time] and [end_time] {
    ruby {
      code => "
        start_time = event.get('start_time')
        end_time = event.get('end_time')
        if start_time && end_time
          processing_time = end_time - start_time
          event.set('processing_time_ms', processing_time * 1000)
        end
      "
    }
  }
  
  # Business logic enrichment
  if [service][name] == "order-service" {
    if [order_amount] {
      ruby {
        code => "
          amount = event.get('order_amount')
          if amount
            if amount > 1000
              event.set('order_category', 'premium')
            elsif amount > 100
              event.set('order_category', 'standard')
            else
              event.set('order_category', 'basic')
            end
          end
        "
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "enhanced-logs-%{+YYYY.MM.dd}"
    template_name => "enhanced_logs"
    template_pattern => "enhanced-logs-*"
    template => {
      "index_patterns" => ["enhanced-logs-*"],
      "settings" => {
        "number_of_shards" => 1,
        "number_of_replicas" => 0
      },
      "mappings" => {
        "properties" => {
          "@timestamp" => { "type" => "date" },
          "service" => {
            "properties" => {
              "name" => { "type" => "keyword" }
            }
          },
          "processing_time_ms" => { "type" => "float" },
          "order_category" => { "type" => "keyword" },
          "geoip" => {
            "properties" => {
              "location" => { "type" => "geo_point" }
            }
          }
        }
      }
    }
  }
}
EOF
```

### Index Lifecycle Management
```bash
# Create ILM policy
curl -X PUT "localhost:9200/_ilm/policy/elk-tutorial-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "7d"
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0
          }
        }
      },
      "delete": {
        "min_age": "90d"
      }
    }
  }
}
'
```

---

## 🛡️ Security Setup

### Enable Authentication
```bash
# Create security configuration
cat > security-config.yml << 'EOF'
version: '3.7'
services:
  elasticsearch:
    environment:
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=false
      - xpack.security.transport.ssl.enabled=false
      - ELASTIC_PASSWORD=changeme
    volumes:
      - ./security:/usr/share/elasticsearch/config/certs
      
  kibana:
    environment:
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=changeme
      - xpack.security.enabled=true
EOF

# Generate passwords
docker-compose exec elasticsearch bin/elasticsearch-setup-passwords auto
```

### Create Users and Roles
```bash
# Create custom role
curl -X POST "localhost:9200/_security/role/log_analyst" -H 'Content-Type: application/json' -d'
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["logstash-*", "enhanced-logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ]
}
'

# Create user
curl -X POST "localhost:9200/_security/user/john_analyst" -H 'Content-Type: application/json' -d'
{
  "password": "analyst123",
  "roles": ["log_analyst"],
  "full_name": "John Analyst",
  "email": "john@company.com"
}
'
```

---

## 📱 Real-World Scenarios

### Scenario 1: E-commerce Order Processing
```bash
# Simulate order processing flow
echo "=== Simulating Order Processing ==="

# Create order
curl -X POST "localhost:8080/orders" -H 'Content-Type: application/json' -d'
{
  "customer_id": "CUST001",
  "product_id": "PROD123",
  "quantity": 2,
  "amount": 299.99
}
'

# Process payment
curl -X POST "localhost:8080/payments" -H 'Content-Type: application/json' -d'
{
  "order_id": "ORD001",
  "amount": 299.99,
  "payment_method": "credit_card"
}
'

# Update inventory
curl -X PUT "localhost:8081/inventory/PROD123" -H 'Content-Type: application/json' -d'
{
  "quantity": 98,
  "reserved": 2
}
'
```

### Scenario 2: Error Investigation
```bash
# Simulate application errors
echo "=== Simulating Application Errors ==="

# Database connection error
curl "localhost:8080/orders?cause_db_error=true"

# High response time
curl "localhost:8081/products?slow_query=true"

# Authentication failure
curl -H "Authorization: Bearer invalid_token" "localhost:8082/users"
```

### Scenario 3: Performance Testing
```bash
# Load testing script
echo "=== Performance Testing ==="

# Function to generate load
generate_load() {
    local service=$1
    local endpoint=$2
    local requests=$3
    
    echo "Generating $requests requests to $service$endpoint"
    for i in $(seq 1 $requests); do
        curl -s "localhost:$service$endpoint" > /dev/null &
        if [ $((i % 10)) -eq 0 ]; then
            wait
        fi
    done
    wait
}

# Generate load on all services
generate_load 8080 "/orders" 50
generate_load 8081 "/products" 75
generate_load 8082 "/users" 25
```

---

## 🚨 Monitoring & Alerts

### Create Watcher Alerts
```bash
# Create alert for high error rate
curl -X PUT "localhost:9200/_watcher/watch/high_error_rate" -H 'Content-Type: application/json' -d'
{
  "trigger": {
    "schedule": {
      "interval": "1m"
    }
  },
  "input": {
    "search": {
      "request": {
        "indices": ["logstash-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {
                  "range": {
                    "@timestamp": {
                      "gte": "now-5m"
                    }
                  }
                },
                {
                  "term": {
                    "log.level": "ERROR"
                  }
                }
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.hits.total": {
        "gt": 10
      }
    }
  },
  "actions": {
    "send_email": {
      "email": {
        "to": ["admin@company.com"],
        "subject": "High Error Rate Alert",
        "body": "Error rate has exceeded threshold in the last 5 minutes"
      }
    }
  }
}
'
```

### Create Kibana Alerts
1. Go to **Stack Management** → **Rules and Connectors**
2. Create **Index threshold rule**
3. Set conditions:
   - Index: `logstash-*`
   - When: `count()` is above `100`
   - Over: `5 minutes`
   - Grouped by: `service.name.keyword`

---

## 🔄 Troubleshooting

### Common Issues and Solutions

#### 1. Elasticsearch Not Starting
```bash
# Check logs
docker-compose logs elasticsearch

# Common fix: increase virtual memory
sudo sysctl -w vm.max_map_count=262144

# Make permanent
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

#### 2. Kibana Connection Issues
```bash
# Check Kibana logs
docker-compose logs kibana

# Test Elasticsearch connection
curl -X GET "localhost:9200/_cluster/health"

# Restart Kibana
docker-compose restart kibana
```

#### 3. No Data in Kibana
```bash
# Check if data is reaching Elasticsearch
curl "localhost:9200/_cat/indices?v"

# Check Logstash logs
docker-compose logs logstash

# Check Filebeat logs
docker-compose logs filebeat

# Generate test data
curl http://localhost:8080/orders
```

#### 4. High Memory Usage
```bash
# Check container resource usage
docker stats

# Adjust memory limits in docker-compose.yml
# For Elasticsearch:
# mem_limit: 2g
# For Kibana:
# mem_limit: 1g
```

### Diagnostic Commands
```bash
# Complete health check
./test-scripts.sh

# Check all service endpoints
curl -s localhost:9200/_cluster/health | jq '.status'
curl -s localhost:5601/api/status | jq '.status.overall.state'
curl -s localhost:8080/health
curl -s localhost:8081/health
curl -s localhost:8082/health

# Check data flow
curl "localhost:9200/_cat/indices?v" | grep logstash
curl "localhost:9200/_cat/count/logstash-*"
```

---

## 🎯 Best Practices

### 1. Index Management
```bash
# Use index templates
curl -X PUT "localhost:9200/_index_template/app-logs" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["app-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "app-logs-policy"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "service": {
          "properties": {
            "name": { "type": "keyword" }
          }
        },
        "response_time": { "type": "float" }
      }
    }
  }
}
'
```

### 2. Query Optimization
```bash
# Use filters instead of queries when possible
curl -X GET "localhost:9200/logstash-*/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "filter": [
        {
          "term": {
            "service.name": "order-service"
          }
        },
        {
          "range": {
            "@timestamp": {
              "gte": "now-1h"
            }
          }
        }
      ]
    }
  }
}
'
```

### 3. Monitoring Setup
```bash
# Create monitoring dashboard
cat > monitoring-dashboard.json << 'EOF'
{
  "dashboard": {
    "title": "ELK Stack Monitoring",
    "panels": [
      {
        "title": "Elasticsearch Cluster Health",
        "type": "metric",
        "query": "GET /_cluster/health"
      },
      {
        "title": "Index Size",
        "type": "line",
        "query": "GET /_cat/indices?format=json"
      },
      {
        "title": "Query Performance",
        "type": "histogram",
        "query": "GET /_nodes/stats/indices/search"
      }
    ]
  }
}
EOF
```

### 4. Security Checklist
- [ ] Enable authentication
- [ ] Configure TLS/SSL
- [ ] Set up role-based access
- [ ] Regular security updates
- [ ] Monitor failed login attempts
- [ ] Use strong passwords
- [ ] Enable audit logging

### 5. Performance Tuning
```bash
# Elasticsearch tuning
cat > elasticsearch-tuning.yml << 'EOF'
cluster.name: production-cluster
node.name: node-1
bootstrap.memory_lock: true
indices.memory.index_buffer_size: 20%
indices.queries.cache.size: 20%
indices.requests.cache.size: 5%
thread_pool.write.queue_size: 1000
EOF

# JVM settings
cat > jvm-options.txt << 'EOF'
-Xms2g
-Xmx2g
-XX:+UseG1GC
-XX:G1HeapRegionSize=16m
-XX:+UseStringDeduplication
EOF
```

---

## 🏆 Final Assessment

### Knowledge Check
1. **Setup**: Can you deploy ELK Stack with one command?
2. **Configuration**: Can you create custom Logstash pipelines?
3. **Visualization**: Can you build meaningful dashboards?
4. **Troubleshooting**: Can you diagnose and fix common issues?
5. **Security**: Can you implement basic security measures?
6. **Performance**: Can you optimize for production use?

### Practical Exercise
```bash
# Complete workflow exercise
echo "=== Final Exercise ==="

# 1. Setup environment
./setup-docker.sh

# 2. Generate sample data
for i in {1..100}; do
    curl -s "localhost:8080/orders?customer_id=CUST$i&amount=$((RANDOM % 1000 + 50))" > /dev/null
done

# 3. Create analysis
echo "Create a dashboard showing:"
echo "- Order volume over time"
echo "- Average order value"
echo "- Customer distribution"
echo "- Error rate monitoring"

# 4. Set up alerts
echo "Configure alerts for:"
echo "- High error rate (>5%)"
echo "- Low order volume (<10/hour)"
echo "- High response time (>2s)"

# 5. Performance optimization
echo "Optimize for:"
echo "- Query performance"
echo "- Memory usage"
echo "- Disk space"
```

### Next Steps
1. **Production Deployment**: Use Kubernetes setup
2. **Advanced Features**: Machine learning, anomaly detection
3. **Integration**: Connect with other tools (Prometheus, Grafana)
4. **Scaling**: Multi-node clusters, load balancing
5. **Automation**: CI/CD integration, automated deployments

---

## 🎓 Congratulations!

You've completed the comprehensive ELK Stack hands-on tutorial! You should now be able to:

✅ **Deploy** ELK Stack in multiple environments  
✅ **Configure** all components for production use  
✅ **Create** meaningful dashboards and visualizations  
✅ **Troubleshoot** common issues and problems  
✅ **Optimize** performance for your specific needs  
✅ **Secure** your ELK Stack deployment  
✅ **Monitor** and maintain your system  

## 📚 Additional Resources

- **Official Documentation**: https://www.elastic.co/guide/
- **Community Forums**: https://discuss.elastic.co/
- **GitHub Repository**: https://github.com/giangianna14/elk-stack-tutorial
- **Best Practices**: https://www.elastic.co/guide/en/elasticsearch/reference/current/best-practices.html

## 🤝 Support

If you encounter any issues or have questions:
1. Check the troubleshooting section
2. Run `./test-scripts.sh` for diagnostics
3. Review the logs with `docker-compose logs`
4. Open an issue on GitHub
5. Join the community discussions

Happy monitoring with ELK Stack! 🚀
