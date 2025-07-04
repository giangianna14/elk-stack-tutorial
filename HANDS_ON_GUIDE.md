# 🚀 ELK Stack Complete Hands-On Guide

Tutorial lengkap hands-on penggunaan ELK Stack dari awal sampai akhir dengan contoh praktis dan real-world scenarios.

## 🆕 **Updated for Kibana 8.14.1**

This guide is specifically updated for **Kibana 8.14.1** and includes all the latest features:

### ✨ **New Features in Kibana 8.14.1:**
- **📊 Data Views**: Replaces Index Patterns with enhanced field management
- **🎨 Lens**: Unified visualization editor with drag-and-drop interface
- **⚡ Runtime Fields**: Create calculated fields without reindexing
- **🎛️ Dashboard Controls**: Interactive filters and time range controls
- **🔍 Enhanced KQL**: Improved Kibana Query Language with better autocomplete
- **🚨 Advanced Alerting**: ML-based anomaly detection and webhook notifications
- **🗺️ Improved Maps**: Enhanced geographic visualizations
- **📱 Mobile Responsive**: Better mobile experience for dashboards
- **🔐 Spaces**: Multi-tenant architecture for team collaboration
- **⚙️ Performance**: Enhanced caching and query optimization

### 💡 **What's Different from Previous Versions:**
- **Index Patterns** → **Data Views** (with runtime field support)
- **Visualize** → **Lens** (unified visualization creation)
- **Watcher** → **Alerting Rules** (integrated alerting framework)
- **Spaces** for better multi-tenancy
- **Enhanced Security** with field-level permissions

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

### Step 2: Create Data View (Kibana 8.14.1)
1. Go to **Management** → **Stack Management**
2. Click **Data Views** under Kibana (previously called Index Patterns)
3. Click **Create data view**
4. Enter **Name**: `logstash-data-view`
5. Enter **Index pattern**: `logstash-*`
6. Select **Timestamp field**: `@timestamp`
7. Click **Save data view to Kibana**

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

### Step 4: Explore Data in Discover (Kibana 8.14.1)
1. Go to **Discover** in the main navigation
2. Select your `logstash-data-view` from the data view dropdown
3. You should see logs flowing in with the new unified search experience
4. Use KQL (Kibana Query Language) to filter:
   - `service.name: "order-service"`
   - `log.level: "ERROR"`
   - `@timestamp >= now-1h`
5. Use the **Add filter** button for complex filtering
6. Explore the **Document table** with improved layout in Kibana 8.14

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

## 📈 Creating Dashboards (Kibana 8.14.1)

### Step 1: Create Visualizations with Lens

#### 1. Service Request Count (Using Lens)
1. Go to **Visualize Library** → **Create visualization**
2. Select **Lens** (the unified visualization editor in Kibana 8.14)
3. Select your `logstash-data-view`
4. **Chart type**: Vertical bar chart
5. **Vertical axis**: Drag **Count of records** 
6. **Horizontal axis**: Drag **service.name.keyword** → **Top 5 values**
7. **Save** as "Service Request Count"

#### 2. Response Time Over Time (Using Lens)
1. Create new **Lens** visualization
2. **Chart type**: Line chart
3. **Vertical axis**: Drag **response_time** → **Average**
4. **Horizontal axis**: Drag **@timestamp** → **Date histogram**
5. **Breakdown by**: Drag **service.name.keyword** → **Top 5 values**
6. **Save** as "Response Time Trend"

#### 3. Error Rate Metric (Using Lens)
1. Create new **Lens** visualization  
2. **Chart type**: Metric
3. **Primary metric**: 
   - Add **Count of records** with filter `log.level: "ERROR"`
   - Add **Count of records** (total) as secondary metric
4. **Save** as "Error Rate"

#### 4. Geographic Distribution (New in 8.14)
1. Create new **Lens** visualization
2. **Chart type**: Map
3. **Layer**: Choropleth
4. **Boundaries**: World Countries
5. **Metrics**: Count of records by **geoip.country_name**
6. **Save** as "Geographic Distribution"

### Step 2: Create Dashboard (Kibana 8.14.1)
1. Go to **Dashboard** → **Create dashboard**
2. Click **Add from library** to add your saved visualizations
3. Add all four visualizations (Service Request Count, Response Time, Error Rate, Geographic Distribution)
4. Use the **improved layout engine** in Kibana 8.14 to arrange panels
5. **Resize and move** panels using the enhanced drag-and-drop interface
6. **Add filters** at the dashboard level for interactive filtering
7. **Save** as "E-commerce Monitoring Dashboard"

### Step 3: Advanced Dashboard Features (Kibana 8.14.1)
1. **Add Markdown panel** with enhanced formatting:
   - Click **Create panel** → **Text**
   - Use the **rich text editor** with improved formatting options

```markdown
# 🛍️ E-commerce Platform Dashboard

## 📊 Key Performance Indicators
- **Total Orders**: Real-time order processing metrics
- **Response Time**: API performance monitoring with P95/P99 percentiles
- **Error Rate**: System health and reliability indicators
- **Geographic Distribution**: Customer location analytics

## 🎯 Business Impact Metrics
- **Order Processing Efficiency**: Track order fulfillment speed
- **Customer Experience**: Monitor response times and error rates
- **Revenue Tracking**: Real-time sales and conversion metrics
- **Operational Health**: System performance and availability

## 🔄 Data Refresh
This dashboard updates in real-time with **15-second intervals**
```

2. **Add Controls** (new in 8.14):
   - Click **Add panel** → **Controls**
   - Add **Options list** control for `service.name.keyword`
   - Add **Time range** control for custom time filtering
   - Add **Range slider** for response time filtering

3. **Configure Dashboard Settings**:
   - Enable **Sync cursor** for coordinated highlighting
   - Set **Auto-refresh** to 15 seconds
   - Configure **Time picker** to show last 4 hours by default

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

### Create Kibana Alerting Rules (Kibana 8.14.1)
1. Go to **Stack Management** → **Rules and Connectors**
2. Click **Create rule**
3. **Rule type**: Select **Elasticsearch query**
4. **Name**: "High Error Rate Alert"
5. **Index**: `logstash-*`
6. **Time field**: `@timestamp`
7. **Query**: 
   ```json
   {
     "query": {
       "bool": {
         "must": [
           {
             "term": {
               "log.level": "ERROR"
             }
           }
         ]
       }
     }
   }
   ```
8. **Conditions**:
   - **When**: `count()` 
   - **IS ABOVE**: `10`
   - **FOR THE LAST**: `5 minutes`
9. **Actions**: 
   - **Connector type**: Email (configure SMTP settings)
   - **To**: `admin@company.com`
   - **Subject**: `High Error Rate Alert - {{context.title}}`
   - **Body**: Use template variables:
     ```
     Alert: {{context.title}}
     
     Error count: {{context.value}}
     Time: {{context.date}}
     
     Query: {{context.conditions}}
     ```
10. **Save** the rule

### Advanced Alerting with Machine Learning (Kibana 8.14.1)
1. Go to **Machine Learning** → **Anomaly Detection**
2. **Create job**:
   - **Job type**: Single metric
   - **Data view**: `logstash-data-view`
   - **Aggregation**: Count
   - **Bucket span**: 15 minutes
   - **Detector**: High count
3. **Configure advanced settings**:
   - **Model plot**: Enable for detailed analysis
   - **Dedicated index**: Enable for performance
4. **Create alert** for ML anomalies:
   - **Rule type**: ML anomaly detection alert
   - **Severity threshold**: 75
   - **Include interim results**: Enable

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

### Diagnostic Commands (Kibana 8.14.1)
```bash
# Complete health check
./test-scripts.sh

# Check all service endpoints with improved error handling
curl -s localhost:9200/_cluster/health | jq '.status' || echo "Elasticsearch not responding"
curl -s localhost:5601/api/status | jq '.status.overall.state' || echo "Kibana not responding"

# Check Kibana 8.14 specific endpoints
curl -s localhost:5601/api/features | jq '.[] | select(.id == "dashboard") | .app'
curl -s localhost:5601/api/data_views | jq '.data_view[] | .title'

# Test sample applications
curl -s localhost:8080/health || echo "Order service not responding"
curl -s localhost:8081/health || echo "Product service not responding"
curl -s localhost:8082/health || echo "User service not responding"

# Check data flow with enhanced filtering
curl "localhost:9200/_cat/indices?v&h=index,docs.count,store.size" | grep logstash
curl "localhost:9200/_cat/count/logstash-*?v"

# Check Kibana data views
curl -s localhost:5601/api/data_views | jq '.data_view[] | {title: .title, timeFieldName: .timeFieldName}'
```

---

## 🎯 Best Practices (Kibana 8.14.1)

### 1. Data View Management
```bash
# Create data view with runtime fields (new in 8.14)
curl -X POST "localhost:5601/api/data_views/data_view" -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -d'
{
  "data_view": {
    "title": "enhanced-logs-*",
    "timeFieldName": "@timestamp",
    "runtimeFieldMap": {
      "order_priority": {
        "type": "keyword",
        "script": {
          "source": "if (doc[\"order_amount\"].size() > 0) { double amount = doc[\"order_amount\"].value; if (amount > 1000) emit(\"high\"); else if (amount > 100) emit(\"medium\"); else emit(\"low\"); }"
        }
      },
      "response_time_category": {
        "type": "keyword", 
        "script": {
          "source": "if (doc[\"response_time\"].size() > 0) { double time = doc[\"response_time\"].value; if (time > 2000) emit(\"slow\"); else if (time > 1000) emit(\"medium\"); else emit(\"fast\"); }"
        }
      }
    }
  }
}
'
```

### 2. Advanced Query Optimization (KQL in 8.14)
```bash
# Use KQL for better performance in Kibana 8.14
# Instead of: service.name: "order-service" AND log.level: "ERROR"
# Use: service.name: "order-service" and log.level: "ERROR"

# Enhanced filtering with wildcards
# service.name: order* and @timestamp >= now-1h

# Boolean queries with improved syntax
# (service.name: "order-service" or service.name: "payment-service") and not log.level: "DEBUG"
```

### 3. Lens Visualization Best Practices
```bash
# Create reusable visualization templates
cat > lens-templates.json << 'EOF'
{
  "service_performance_template": {
    "datasourceStates": {
      "formBased": {
        "layers": {
          "layer1": {
            "columns": {
              "col1": {
                "operationType": "date_histogram",
                "sourceField": "@timestamp",
                "params": {
                  "interval": "auto"
                }
              },
              "col2": {
                "operationType": "average",
                "sourceField": "response_time",
                "params": {
                  "format": {
                    "id": "number",
                    "params": {
                      "decimals": 2
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
EOF
```

### 4. Dashboard Performance Optimization (Kibana 8.14.1)
```bash
# Configure dashboard caching
cat > kibana-performance.yml << 'EOF'
# Enhanced caching in Kibana 8.14
data.search.sessions.enabled: true
data.search.sessions.defaultExpiration: 7d
data.search.sessions.management.maxSessions: 100

# Improved query performance
data.search.timeout: 30s
data.search.max_buckets: 100000

# Dashboard-specific optimizations
dashboard.allowByValueEmbeddables: false
visualizations.legacyChartsLibrary: false
EOF
```

### 5. Security Best Practices (Kibana 8.14.1)
```bash
# Create space-based security
curl -X POST "localhost:5601/api/spaces/space" -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -d'
{
  "id": "ecommerce-analytics",
  "name": "E-commerce Analytics",
  "description": "Space for e-commerce monitoring and analytics",
  "initials": "EA",
  "color": "#00BFB3",
  "disabledFeatures": ["dev_tools", "monitoring"]
}
'

# Create role with space-specific permissions
curl -X POST "localhost:9200/_security/role/ecommerce_analyst" -H 'Content-Type: application/json' -d'
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["logstash-*", "enhanced-logs-*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["feature_dashboard.read", "feature_discover.read", "feature_visualize.read"],
      "resources": ["space:ecommerce-analytics"]
    }
  ]
}
'
```

### 6. Machine Learning Integration (Kibana 8.14.1)
```bash
# Create ML job for anomaly detection
curl -X PUT "localhost:9200/_ml/anomaly_detectors/ecommerce-anomaly-detection" -H 'Content-Type: application/json' -d'
{
  "job_id": "ecommerce-anomaly-detection",
  "description": "Detect anomalies in e-commerce metrics",
  "analysis_config": {
    "bucket_span": "15m",
    "detectors": [
      {
        "detector_description": "High order count",
        "function": "high_count",
        "by_field_name": "service.name.keyword"
      },
      {
        "detector_description": "Mean response time",
        "function": "mean",
        "field_name": "response_time",
        "by_field_name": "service.name.keyword"
      }
    ]
  },
  "data_description": {
    "time_field": "@timestamp",
    "time_format": "epoch_ms"
  }
}
'
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

### Practical Exercise (Kibana 8.14.1)
```bash
# Complete workflow exercise with Kibana 8.14 features
echo "=== Final Exercise - Kibana 8.14.1 ==="

# 1. Setup environment
./setup-docker.sh

# 2. Generate sample data with business context
for i in {1..100}; do
    customer_id="CUST$(printf "%03d" $i)"
    amount=$((RANDOM % 1000 + 50))
    priority=$( [ $amount -gt 500 ] && echo "high" || echo "normal" )
    
    curl -s "localhost:8080/orders?customer_id=$customer_id&amount=$amount&priority=$priority" > /dev/null
    
    # Add some errors for testing
    if [ $((i % 10)) -eq 0 ]; then
        curl -s "localhost:8080/orders?simulate_error=true" > /dev/null
    fi
done

# 3. Create enhanced analysis with Kibana 8.14.1
echo "Tasks to complete in Kibana 8.14.1:"
echo ""
echo "📊 DATA VIEWS:"
echo "- Create data view with runtime fields for order priority"
echo "- Add calculated fields for response time categories"
echo ""
echo "🎨 LENS VISUALIZATIONS:"
echo "- Order volume trend (using date histogram)"
echo "- Average order value by priority (using Lens metrics)"
echo "- Geographic distribution map (using new map features)"
echo "- Error rate over time (using formula functions)"
echo ""
echo "📈 DASHBOARD FEATURES:"
echo "- Add interactive controls for filtering"
echo "- Use markdown panels with rich formatting"
echo "- Configure auto-refresh and time sync"
echo "- Add drilldown actions between visualizations"
echo ""
echo "🚨 ALERTING & ML:"
echo "- Create Elasticsearch query rules for error rate"
echo "- Set up ML anomaly detection job"
echo "- Configure webhook notifications"
echo ""
echo "🔧 ADVANCED FEATURES:"
echo "- Use KQL for complex filtering"
echo "- Create saved searches with runtime fields"
echo "- Set up dashboard spaces for team collaboration"
echo "- Configure data view field formatters"

# 4. Performance optimization checklist
echo ""
echo "⚡ PERFORMANCE OPTIMIZATION:"
echo "- Enable dashboard caching"
echo "- Use index patterns with appropriate time ranges"
echo "- Optimize Lens visualizations for large datasets"
echo "- Configure query timeout settings"
```

### Next Steps
1. **Production Deployment**: Use Kubernetes setup
2. **Advanced Features**: Machine learning, anomaly detection
3. **Integration**: Connect with other tools (Prometheus, Grafana)
4. **Scaling**: Multi-node clusters, load balancing
5. **Automation**: CI/CD integration, automated deployments

---

## 🎓 Congratulations! (Kibana 8.14.1 Edition)

You've completed the comprehensive ELK Stack hands-on tutorial updated for Kibana 8.14.1! You should now be able to:

✅ **Deploy** ELK Stack in multiple environments with latest features  
✅ **Create Data Views** with runtime fields and advanced field mapping  
✅ **Use Lens** for unified visualization creation with enhanced capabilities  
✅ **Build Interactive Dashboards** with controls, filters, and auto-refresh  
✅ **Implement Modern Alerting** with Elasticsearch query rules and ML integration  
✅ **Apply KQL** for advanced querying and filtering  
✅ **Configure Security** with spaces, roles, and field-level permissions  
✅ **Optimize Performance** with caching and query optimization  
✅ **Troubleshoot** using enhanced diagnostic tools and APIs  

### 🆕 New Features in Kibana 8.14.1 You've Mastered:

**📊 Data Views & Runtime Fields**
- Created dynamic calculated fields without reindexing
- Implemented business logic in runtime field scripts
- Enhanced data exploration with on-the-fly transformations

**🎨 Lens Unified Visualization**
- Built all visualization types in a single interface
- Used formula functions for complex calculations
- Created reusable visualization templates

**📈 Enhanced Dashboards**
- Added interactive controls for dynamic filtering
- Implemented auto-refresh and time synchronization
- Used markdown panels with rich text formatting

**🚨 Advanced Alerting**
- Created Elasticsearch query-based rules
- Integrated machine learning anomaly detection
- Configured multiple notification channels

**🔧 Performance & Security**
- Optimized dashboards with caching strategies
- Implemented space-based security model
- Enhanced query performance with KQL  

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
