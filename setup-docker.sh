#!/bin/bash

# ELK Stack Tutorial - Docker Setup Script
# This script sets up the entire ELK stack using Docker Compose
# Author: ELK Tutorial Team
# Version: 2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}  ELK Stack Docker Setup${NC}"
echo -e "${BLUE}=================================${NC}"
echo

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    # Check available disk space (minimum 10GB recommended)
    available_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/[^0-9]*//g')
    if [ "$available_space" -lt 10 ]; then
        print_warning "Low disk space detected. ELK Stack requires at least 10GB of free space."
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check available memory (minimum 8GB recommended)
    available_memory=$(free -g | awk 'NR==2{print $7}')
    if [ "$available_memory" -lt 6 ]; then
        print_warning "Low memory detected. ELK Stack requires at least 6GB of available memory."
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_status "Prerequisites check completed ✓"
}

# Set up Docker environment
setup_docker_environment() {
    print_status "Setting up Docker environment..."
    
    # Set vm.max_map_count for Elasticsearch
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        current_max_map_count=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
        if [ "$current_max_map_count" -lt 262144 ]; then
            print_status "Setting vm.max_map_count for Elasticsearch..."
            if [ "$EUID" -eq 0 ]; then
                echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
                sysctl -p
            else
                print_warning "Cannot set vm.max_map_count (requires root). Elasticsearch may not start properly."
                echo "Run: sudo sysctl -w vm.max_map_count=262144"
                read -p "Continue anyway? (y/N): " confirm
                if [[ ! $confirm =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
        fi
    fi
    
    print_status "Docker environment setup completed ✓"
}

# Create required directories
create_directories() {
    print_status "Creating required directories..."
    
    # Create config directories
    mkdir -p 02-beats/filebeat
    mkdir -p 04-logstash/config
    mkdir -p 04-logstash/pipelines
    mkdir -p 05-elasticsearch/config
    mkdir -p 06-kibana/config
    mkdir -p 01-openshift/sample-apps/html
    mkdir -p logs/{order-service,product-service,user-service,generator}
    
    # Set proper permissions
    chmod 755 logs/
    chmod -R 755 logs/
    
    print_status "Directories created ✓"
}

# Create configuration files
create_config_files() {
    print_status "Creating configuration files..."
    
    # Create Elasticsearch config
    cat > 05-elasticsearch/config/elasticsearch.yml << EOF
cluster.name: elk-cluster
node.name: elasticsearch
path.data: /usr/share/elasticsearch/data
path.logs: /usr/share/elasticsearch/logs
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: false
xpack.security.enrollment.enabled: false
xpack.ml.enabled: false
EOF

    # Create Kibana config
    cat > 06-kibana/config/kibana.yml << EOF
server.name: kibana
server.host: 0.0.0.0
server.port: 5601
elasticsearch.hosts: ["http://elasticsearch:9200"]
elasticsearch.requestTimeout: 90000
xpack.security.enabled: false
xpack.monitoring.ui.container.elasticsearch.enabled: true
logging.level: warn
EOF

    # Create Logstash config
    cat > 04-logstash/config/logstash.yml << EOF
http.host: "0.0.0.0"
path.config: /usr/share/logstash/pipeline
path.logs: /usr/share/logstash/logs
xpack.monitoring.enabled: false
EOF

    # Create Logstash pipeline
    cat > 04-logstash/pipelines/applications.conf << EOF
input {
  beats {
    port => 5044
  }
  
  kafka {
    bootstrap_servers => "kafka:9092"
    topics => ["logs", "metrics", "events"]
    codec => "json"
  }
}

filter {
  if [fields][service] {
    mutate {
      add_field => { "service_name" => "%{[fields][service]}" }
    }
  }
  
  if [message] =~ /ERROR/ {
    mutate {
      add_tag => ["error"]
      add_field => { "log_level" => "error" }
    }
  } else if [message] =~ /WARN/ {
    mutate {
      add_tag => ["warning"]
      add_field => { "log_level" => "warning" }
    }
  } else {
    mutate {
      add_field => { "log_level" => "info" }
    }
  }
  
  # Parse nginx logs
  if [fields][log_type] == "nginx" {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
    
    mutate {
      convert => { "response" => "integer" }
      convert => { "bytes" => "integer" }
    }
  }
  
  # Add timestamp
  mutate {
    add_field => { "processed_at" => "%{@timestamp}" }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
    
    # Route different log types to different indices
    if [fields][service] == "order-service" {
      index => "orders-%{+YYYY.MM.dd}"
    } else if [fields][service] == "product-service" {
      index => "products-%{+YYYY.MM.dd}"
    } else if [fields][service] == "user-service" {
      index => "users-%{+YYYY.MM.dd}"
    }
  }
  
  # Debug output
  if [fields][debug] {
    stdout {
      codec => rubydebug
    }
  }
}
EOF

    # Create Filebeat config
    cat > 02-beats/filebeat/filebeat-docker.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
  fields:
    log_type: nginx
    service: web
  fields_under_root: true
  multiline.pattern: '^[[:space:]]'
  multiline.negate: false
  multiline.match: after

- type: container
  enabled: true
  paths:
    - /var/lib/docker/containers/*/*.log
  processors:
    - add_docker_metadata:
        host: "unix:///var/run/docker.sock"

- type: log
  enabled: true
  paths:
    - /var/log/order-service/*.log
  fields:
    service: order-service
    log_type: nginx
  fields_under_root: true

- type: log
  enabled: true
  paths:
    - /var/log/product-service/*.log
  fields:
    service: product-service
    log_type: nginx
  fields_under_root: true

- type: log
  enabled: true
  paths:
    - /var/log/user-service/*.log
  fields:
    service: user-service
    log_type: nginx
  fields_under_root: true

output.logstash:
  hosts: ["logstash:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
EOF

    print_status "Configuration files created ✓"
}

# Create sample applications config
create_sample_apps() {
    print_status "Creating sample applications..."
    
    # Create nginx configs for sample services
    cat > 01-openshift/sample-apps/order-service-docker.conf << EOF
server {
    listen 80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /api/orders {
        add_header Content-Type application/json;
        return 200 '{"orders": [{"id": 1, "status": "processing"}, {"id": 2, "status": "shipped"}]}';
    }
    
    location /health {
        add_header Content-Type application/json;
        return 200 '{"status": "healthy", "service": "order-service"}';
    }
}
EOF

    cat > 01-openshift/sample-apps/product-service-docker.conf << EOF
server {
    listen 80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /api/products {
        add_header Content-Type application/json;
        return 200 '{"products": [{"id": 1, "name": "Laptop"}, {"id": 2, "name": "Mouse"}]}';
    }
    
    location /health {
        add_header Content-Type application/json;
        return 200 '{"status": "healthy", "service": "product-service"}';
    }
}
EOF

    cat > 01-openshift/sample-apps/user-service-docker.conf << EOF
server {
    listen 80;
    server_name localhost;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    
    location /api/users {
        add_header Content-Type application/json;
        return 200 '{"users": [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]}';
    }
    
    location /health {
        add_header Content-Type application/json;
        return 200 '{"status": "healthy", "service": "user-service"}';
    }
}
EOF

    # Create sample HTML pages
    cat > 01-openshift/sample-apps/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>ELK Stack Demo - E-commerce Platform</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .service { background: #f4f4f4; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .api-endpoint { background: #e8f4f8; padding: 10px; margin: 10px 0; border-radius: 4px; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛍️ E-commerce Platform Demo</h1>
        <p>Welcome to our ELK Stack demonstration platform. This simulates a microservices-based e-commerce application.</p>
        
        <div class="service">
            <h2>📦 Order Service</h2>
            <p>Manages customer orders and order processing.</p>
            <div class="api-endpoint">
                <strong>API Endpoints:</strong><br>
                <a href="/api/orders">/api/orders</a> - Get all orders<br>
                <a href="/health">/health</a> - Health check
            </div>
        </div>
        
        <div class="service">
            <h2>🛒 Product Service</h2>
            <p>Manages product catalog and inventory.</p>
            <div class="api-endpoint">
                <strong>API Endpoints:</strong><br>
                <a href="/api/products">/api/products</a> - Get all products<br>
                <a href="/health">/health</a> - Health check
            </div>
        </div>
        
        <div class="service">
            <h2>👥 User Service</h2>
            <p>Manages user accounts and authentication.</p>
            <div class="api-endpoint">
                <strong>API Endpoints:</strong><br>
                <a href="/api/users">/api/users</a> - Get all users<br>
                <a href="/health">/health</a> - Health check
            </div>
        </div>
        
        <h2>🔧 ELK Stack Components</h2>
        <ul>
            <li><a href="http://localhost:5601" target="_blank">Kibana Dashboard</a> - Data visualization</li>
            <li><a href="http://localhost:9200" target="_blank">Elasticsearch</a> - Search and analytics</li>
            <li><a href="http://localhost:8090" target="_blank">Kafka UI</a> - Message streaming</li>
            <li><a href="http://localhost:9100" target="_blank">Elasticsearch Head</a> - Cluster monitoring</li>
        </ul>
    </div>
</body>
</html>
EOF

    print_status "Sample applications created ✓"
}

# Start ELK Stack
start_elk_stack() {
    print_status "Starting ELK Stack with Docker Compose..."
    
    # Use docker-compose if available, otherwise use docker compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
    
    # Start core services first
    print_status "Starting infrastructure services..."
    $COMPOSE_CMD up -d zookeeper kafka elasticsearch
    
    # Wait for core services to be ready
    print_status "Waiting for core services to be ready..."
    sleep 30
    
    # Start ELK components
    print_status "Starting ELK components..."
    $COMPOSE_CMD up -d kibana logstash
    
    # Wait for ELK to be ready
    print_status "Waiting for ELK components to be ready..."
    sleep 20
    
    # Start monitoring and sample apps
    print_status "Starting monitoring and sample applications..."
    $COMPOSE_CMD up -d filebeat order-service product-service user-service kafka-ui elasticsearch-head log-generator
    
    print_status "ELK Stack started successfully ✓"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for all services to be ready..."
    
    # Wait for Elasticsearch
    print_status "Waiting for Elasticsearch..."
    timeout 300 bash -c 'until curl -s http://localhost:9200/_cluster/health; do sleep 5; done' || {
        print_error "Elasticsearch failed to start"
        exit 1
    }
    
    # Wait for Kibana
    print_status "Waiting for Kibana..."
    timeout 300 bash -c 'until curl -s http://localhost:5601/api/status; do sleep 5; done' || {
        print_error "Kibana failed to start"
        exit 1
    }
    
    # Wait for Logstash
    print_status "Waiting for Logstash..."
    timeout 300 bash -c 'until curl -s http://localhost:9600/_node/stats; do sleep 5; done' || {
        print_error "Logstash failed to start"
        exit 1
    }
    
    print_status "All services are ready ✓"
}

# Setup initial data
setup_initial_data() {
    print_status "Setting up initial data and index templates..."
    
    # Create index templates
    curl -X PUT "localhost:9200/_index_template/logs-template" -H 'Content-Type: application/json' -d'
    {
      "index_patterns": ["logs-*"],
      "template": {
        "settings": {
          "number_of_shards": 1,
          "number_of_replicas": 0
        },
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "message": { "type": "text" },
            "log_level": { "type": "keyword" },
            "service_name": { "type": "keyword" },
            "host": { "type": "keyword" }
          }
        }
      }
    }' || print_warning "Failed to create logs template"
    
    # Generate some initial traffic
    print_status "Generating initial traffic..."
    for i in {1..10}; do
        curl -s http://localhost:8080/api/orders > /dev/null || true
        curl -s http://localhost:8081/api/products > /dev/null || true
        curl -s http://localhost:8082/api/users > /dev/null || true
        sleep 1
    done
    
    print_status "Initial data setup completed ✓"
}

# Display access information
display_access_info() {
    echo
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}    ELK Stack Setup Completed!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo
    echo -e "${BLUE}🌐 Access URLs:${NC}"
    echo -e "  Kibana Dashboard: ${GREEN}http://localhost:5601${NC}"
    echo -e "  Elasticsearch: ${GREEN}http://localhost:9200${NC}"
    echo -e "  Kafka UI: ${GREEN}http://localhost:8090${NC}"
    echo -e "  Elasticsearch Head: ${GREEN}http://localhost:9100${NC}"
    echo
    echo -e "${BLUE}🛍️ Sample Applications:${NC}"
    echo -e "  Order Service: ${GREEN}http://localhost:8080${NC}"
    echo -e "  Product Service: ${GREEN}http://localhost:8081${NC}"
    echo -e "  User Service: ${GREEN}http://localhost:8082${NC}"
    echo
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo -e "  View logs: ${YELLOW}docker-compose logs -f <service>${NC}"
    echo -e "  Stop stack: ${YELLOW}docker-compose down${NC}"
    echo -e "  Remove data: ${YELLOW}docker-compose down -v${NC}"
    echo -e "  Scale service: ${YELLOW}docker-compose up -d --scale <service>=<count>${NC}"
    echo
    echo -e "${BLUE}📊 Next Steps:${NC}"
    echo "1. Access Kibana at http://localhost:5601"
    echo "2. Create index patterns for logs-*"
    echo "3. Explore sample data and create visualizations"
    echo "4. Test the sample applications"
    echo "5. Monitor Kafka topics in Kafka UI"
    echo
    echo -e "${YELLOW}Note: It may take a few minutes for all logs to appear in Kibana${NC}"
}

# Main execution
main() {
    check_prerequisites
    setup_docker_environment
    create_directories
    create_config_files
    create_sample_apps
    start_elk_stack
    wait_for_services
    setup_initial_data
    display_access_info
}

# Handle script interruption
trap 'echo -e "\n${RED}Setup interrupted. Cleaning up...${NC}"; docker-compose down; exit 1' INT TERM

# Run main function
main "$@"
