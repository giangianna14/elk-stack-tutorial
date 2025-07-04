#!/bin/bash

# ELK Stack Tutorial - Docker Uninstall Script
# This script removes all ELK stack Docker containers and volumes
# Author: ELK Tutorial Team
# Version: 2.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}=======================================${NC}"
echo -e "${RED}  ELK Stack Docker - UNINSTALL${NC}"
echo -e "${RED}=======================================${NC}"
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

# Check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check for Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose is not available"
        exit 1
    fi
    
    print_status "Docker environment detected ✓"
}

# Show warning about what will be deleted
show_warning() {
    echo -e "${RED}⚠️  WARNING: This will completely remove all ELK stack Docker components! ⚠️${NC}"
    echo
    echo -e "${YELLOW}The following will be deleted:${NC}"
    echo "🐳 Docker Containers:"
    echo "   - elasticsearch"
    echo "   - kibana"
    echo "   - logstash"
    echo "   - kafka"
    echo "   - zookeeper"
    echo "   - filebeat"
    echo "   - order-service"
    echo "   - product-service"
    echo "   - user-service"
    echo "   - kafka-ui"
    echo "   - elasticsearch-head"
    echo "   - log-generator"
    echo
    echo "💾 Docker Volumes:"
    echo "   - elasticsearch_data"
    echo "   - kibana_data"
    echo "   - kafka_data"
    echo "   - zookeeper_data"
    echo "   - zookeeper_logs"
    echo "   - filebeat_data"
    echo
    echo "🌐 Docker Network:"
    echo "   - elk-network"
    echo
    echo "📁 Local Files:"
    echo "   - Configuration files"
    echo "   - Log files"
    echo "   - Sample application files"
    echo
    echo "💾 Data:"
    echo "   - All log data in Elasticsearch"
    echo "   - All Kafka topics and messages"
    echo "   - All persistent volumes"
    echo "   - All dashboards and configurations"
    echo
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Uninstall cancelled."
        exit 0
    fi
}

# Stop and remove containers
stop_and_remove_containers() {
    print_status "Stopping and removing Docker containers..."
    
    # Stop all services
    if [ -f "docker-compose.yml" ]; then
        print_status "Stopping services with Docker Compose..."
        $COMPOSE_CMD down --timeout 30 || print_warning "Some services may have already been stopped"
    else
        print_warning "docker-compose.yml not found, stopping containers manually..."
        
        # Stop containers manually
        containers=(
            "elasticsearch"
            "kibana"
            "logstash"
            "kafka"
            "zookeeper"
            "filebeat"
            "order-service"
            "product-service"
            "user-service"
            "kafka-ui"
            "elasticsearch-head"
            "log-generator"
        )
        
        for container in "${containers[@]}"; do
            if docker ps -q -f name="$container" | grep -q .; then
                print_status "Stopping container: $container"
                docker stop "$container" || true
                docker rm "$container" || true
            fi
        done
    fi
    
    print_status "Containers stopped and removed ✓"
}

# Remove volumes
remove_volumes() {
    print_status "Removing Docker volumes..."
    
    # Remove named volumes
    volumes=(
        "elk-tutorial_elasticsearch_data"
        "elk-tutorial_kibana_data"
        "elk-tutorial_kafka_data"
        "elk-tutorial_zookeeper_data"
        "elk-tutorial_zookeeper_logs"
        "elk-tutorial_filebeat_data"
        "elasticsearch_data"
        "kibana_data"
        "kafka_data"
        "zookeeper_data"
        "zookeeper_logs"
        "filebeat_data"
    )
    
    for volume in "${volumes[@]}"; do
        if docker volume ls -q | grep -q "^$volume$"; then
            print_status "Removing volume: $volume"
            docker volume rm "$volume" || true
        fi
    done
    
    # Remove with Docker Compose if available
    if [ -f "docker-compose.yml" ]; then
        print_status "Removing volumes with Docker Compose..."
        $COMPOSE_CMD down -v || true
    fi
    
    print_status "Volumes removed ✓"
}

# Remove network
remove_network() {
    print_status "Removing Docker network..."
    
    networks=(
        "elk-tutorial_elk-network"
        "elk-network"
    )
    
    for network in "${networks[@]}"; do
        if docker network ls -q | grep -q "$network"; then
            print_status "Removing network: $network"
            docker network rm "$network" || true
        fi
    done
    
    print_status "Network removed ✓"
}

# Remove configuration files
remove_config_files() {
    print_status "Removing configuration files..."
    
    # Remove created config files
    config_files=(
        "02-beats/filebeat/filebeat-docker.yml"
        "04-logstash/config/logstash.yml"
        "04-logstash/pipelines/applications.conf"
        "05-elasticsearch/config/elasticsearch.yml"
        "06-kibana/config/kibana.yml"
        "01-openshift/sample-apps/order-service-docker.conf"
        "01-openshift/sample-apps/product-service-docker.conf"
        "01-openshift/sample-apps/user-service-docker.conf"
        "01-openshift/sample-apps/html/index.html"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            print_status "Removing file: $file"
            rm -f "$file"
        fi
    done
    
    # Remove log directories
    if [ -d "logs" ]; then
        print_status "Removing log directories..."
        rm -rf logs/
    fi
    
    # Remove empty directories
    directories=(
        "02-beats/filebeat"
        "04-logstash/config"
        "04-logstash/pipelines"
        "05-elasticsearch/config"
        "06-kibana/config"
        "01-openshift/sample-apps/html"
    )
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ] && [ -z "$(ls -A "$dir")" ]; then
            print_status "Removing empty directory: $dir"
            rmdir "$dir" || true
        fi
    done
    
    print_status "Configuration files removed ✓"
}

# Remove Docker images (optional)
remove_images() {
    echo
    read -p "Do you want to remove Docker images as well? This will free up more disk space. (y/N): " remove_imgs
    if [[ $remove_imgs =~ ^[Yy]$ ]]; then
        print_status "Removing Docker images..."
        
        # Remove ELK stack images
        images=(
            "docker.elastic.co/elasticsearch/elasticsearch:8.14.1"
            "docker.elastic.co/kibana/kibana:8.14.1"
            "docker.elastic.co/logstash/logstash:8.14.1"
            "docker.elastic.co/beats/filebeat:8.14.1"
            "confluentinc/cp-kafka:7.4.0"
            "confluentinc/cp-zookeeper:7.4.0"
            "provectuslabs/kafka-ui:latest"
            "mobz/elasticsearch-head:5"
            "nginx:alpine"
            "mingrammer/flog:latest"
        )
        
        for image in "${images[@]}"; do
            if docker images -q "$image" | grep -q .; then
                print_status "Removing image: $image"
                docker rmi "$image" || true
            fi
        done
        
        # Remove dangling images
        dangling_images=$(docker images -f "dangling=true" -q)
        if [ -n "$dangling_images" ]; then
            print_status "Removing dangling images..."
            docker rmi $dangling_images || true
        fi
        
        print_status "Docker images removed ✓"
    fi
}

# Cleanup system
cleanup_system() {
    print_status "Cleaning up Docker system..."
    
    # Remove unused containers, networks, and images
    docker system prune -f || true
    
    print_status "System cleanup completed ✓"
}

# Verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check for remaining containers
    remaining_containers=$(docker ps -a --format "table {{.Names}}" | grep -E "(elasticsearch|kibana|logstash|kafka|zookeeper|filebeat|order-service|product-service|user-service|kafka-ui|elasticsearch-head|log-generator)" | wc -l)
    
    if [ "$remaining_containers" -gt 0 ]; then
        print_warning "Some containers may still exist:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(elasticsearch|kibana|logstash|kafka|zookeeper|filebeat|order-service|product-service|user-service|kafka-ui|elasticsearch-head|log-generator)" || true
    fi
    
    # Check for remaining volumes
    remaining_volumes=$(docker volume ls --format "table {{.Name}}" | grep -E "(elasticsearch|kibana|kafka|zookeeper|filebeat)" | wc -l)
    
    if [ "$remaining_volumes" -gt 0 ]; then
        print_warning "Some volumes may still exist:"
        docker volume ls --format "table {{.Name}}" | grep -E "(elasticsearch|kibana|kafka|zookeeper|filebeat)" || true
    fi
    
    print_status "Cleanup verification completed ✓"
}

# Main execution
main() {
    check_docker
    show_warning
    
    print_status "Starting ELK Stack Docker uninstall..."
    
    stop_and_remove_containers
    remove_volumes
    remove_network
    remove_config_files
    remove_images
    cleanup_system
    verify_cleanup
    
    echo
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}  ELK Stack Docker Uninstall Complete!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo
    echo -e "${BLUE}Summary:${NC}"
    echo "✓ All Docker containers stopped and removed"
    echo "✓ All Docker volumes removed"
    echo "✓ Docker network removed"
    echo "✓ Configuration files cleaned up"
    echo "✓ System cleanup completed"
    echo
    echo -e "${BLUE}To reinstall the ELK Stack:${NC}"
    echo "- Run: ./setup-docker.sh"
    echo
    echo -e "${YELLOW}Note: Docker images may still exist if you chose not to remove them.${NC}"
    echo -e "${YELLOW}Use 'docker images' to check and 'docker rmi <image>' to remove if needed.${NC}"
}

# Run main function
main "$@"
