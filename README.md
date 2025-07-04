# ELK Stack Tutorial - Complete Learning Platform

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Compatible-green?logo=kubernetes)](https://kubernetes.io/)
[![OpenShift](https://img.shields.io/badge/OpenShift-Ready-red?logo=redhat)](https://www.redhat.com/en/technologies/cloud-computing/openshift)
[![ELK Stack](https://img.shields.io/badge/ELK-8.14-yellow?logo=elastic)](https://www.elastic.co/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-brightgreen)](test-scripts.sh)

Tutorial lengkap untuk membangun ELK Stack (Elasticsearch, Logstash, Kibana) dengan Beats dan Kafka di OpenShift/Kubernetes dan Docker, termasuk real-world use case dan deployment production-ready.

## 📖 Table of Contents

- [🌟 Features](#-features)
- [🚀 Quick Start](#-quick-start)
- [📚 Documentation](#-documentation)
- [🏗️ Architecture](#-architecture)
- [🎯 What You'll Learn](#-what-youll-learn)
- [🔧 Scripts Available](#-scripts-available)
- [💡 Use Cases & Examples](#-use-cases--examples)
- [🛠️ Prerequisites](#-prerequisites)
- [🤝 Support & Troubleshooting](#-support--troubleshooting)
- [📚 Learning Path](#-learning-path)
- [📄 License](#-license)

## 🌟 Features

✅ **Multiple Deployment Options**: Docker, OpenShift, Kubernetes, Local clusters  
✅ **Production-Ready Configuration**: Security, monitoring, scaling  
✅ **Real-World Use Cases**: E-commerce platform monitoring  
✅ **Complete Pipeline**: Log collection → Processing → Storage → Visualization  
✅ **Interactive Learning**: Step-by-step tutorials with troubleshooting  
✅ **One-Command Setup**: Automated installation and configuration

## 🚀 Quick Start

### 1. Setup (Choose one option)

**🐳 Docker Setup (⭐ Recommended for development):**
```bash
./setup-docker.sh
# Complete ELK Stack ready in 5-10 minutes!
# Access: http://localhost:5601 (Kibana)
```

**☸️ Kubernetes/OpenShift Setup:**
```bash
# Full production setup
./setup.sh

# Local cluster (Minikube, Kind, OpenShift Local)
./setup-local-cluster.sh

# Lightweight (minimal resources)
./setup-lightweight.sh
```

### 🧪 Validate Setup
```bash
# Test all components
./test-scripts.sh

# Check Docker services (if using Docker)
docker-compose ps
```

### 2. Access Your ELK Stack

After setup completes, access these URLs:

| Service | URL | Purpose |
|---------|-----|---------|
| **Kibana** | http://localhost:5601 | Data visualization & dashboards |
| **Elasticsearch** | http://localhost:9200 | Search & analytics API |
| **Kafka UI** | http://localhost:8090 | Message streaming monitoring |
| **Order Service** | http://localhost:8080 | Sample e-commerce app |
| **Product Service** | http://localhost:8081 | Sample e-commerce app |
| **User Service** | http://localhost:8082 | Sample e-commerce app |

### 3. Start Exploring Data

**Generate Sample Data:**
```bash
# The log generator automatically creates sample data
# Visit the sample apps to generate more logs:
curl http://localhost:8080/orders
curl http://localhost:8081/products
curl http://localhost:8082/users
```

**Create Kibana Index Pattern:**
1. Go to Kibana: http://localhost:5601
2. Navigate to **Management** → **Index Patterns**
3. Create pattern: `logstash-*`
4. Select timestamp field: `@timestamp`
5. Go to **Discover** to start exploring logs!

### 4. Uninstall (Complete cleanup)

```bash
# Docker setup cleanup
./uninstall-docker.sh

# Kubernetes/OpenShift cleanup
./uninstall.sh
```

## 📚 Documentation

- **[HANDS_ON_GUIDE.md](HANDS_ON_GUIDE.md)** - Complete hands-on tutorial from start to finish
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference for common commands and operations
- **[DOCKER_SETUP_GUIDE.md](DOCKER_SETUP_GUIDE.md)** - Docker-based setup (recommended)
- **[QUICK_START.md](QUICK_START.md)** - Setup cluster dan troubleshooting
- **[TUTORIAL_SUMMARY.md](TUTORIAL_SUMMARY.md)** - Ringkasan lengkap tutorial
- **[UNINSTALL_GUIDE.md](UNINSTALL_GUIDE.md)** - Panduan uninstall dan troubleshooting

## 🏗️ Architecture

### Docker Architecture (Recommended)
```
🐳 Docker Network: elk-network
├── 🔍 Elasticsearch:9200 (Search & Analytics)
├── 📊 Kibana:5601 (Visualization)
├── ⚙️  Logstash:5044,9600 (Processing)
├── 📡 Filebeat (Log Collection)
├── 🚀 Kafka:29092 + Zookeeper (Streaming)
├── 🛍️ E-commerce Apps:
│   ├── Order Service:8080
│   ├── Product Service:8081
│   └── User Service:8082
└── 📈 Monitoring:
    ├── Kafka UI:8090
    └── Elasticsearch Head:9100
```

### Kubernetes/OpenShift Architecture
```
☸️ Kubernetes/OpenShift Cluster
├── 📦 Namespaces: kafka, elastic-system, ecommerce-prod
├── 🛍️ Sample Applications (microservices)
├── 📡 Beats (Filebeat) → Collect logs
├── 🚀 Kafka → Stream processing
├── ⚙️  Logstash → Data transformation
├── 🔍 Elasticsearch → Data storage
└── 📊 Kibana → Visualization & dashboards
```

## 🎯 What You'll Learn

### 🔧 Technical Skills
- **ELK Stack Deployment** in multiple environments (Docker, K8s, OpenShift)
- **Real-time Log Processing** with Beats, Kafka, and Logstash pipelines
- **Data Visualization** with Kibana dashboards and analytics
- **Production-ready Configuration** with security and monitoring
- **Troubleshooting** and performance optimization
- **Container Orchestration** and microservices monitoring

### 💼 Real-World Applications
- **E-commerce Platform Monitoring** - Complete implementation
- **Log Aggregation** from multiple microservices
- **Performance Monitoring** - Response times and throughput
- **Error Tracking** and alerting systems
- **Business Intelligence** dashboards

### 🏆 Key Benefits
- **⚡ Fast Setup**: Complete ELK Stack in 5-10 minutes
- **🔄 Multiple Options**: Docker, K8s, OpenShift, Local clusters
- **📊 Real Data**: Sample e-commerce apps with actual logs
- **🛡️ Production Ready**: Security, monitoring, scaling included
- **🧪 Validated**: All scripts tested and working
- **📚 Comprehensive**: Full documentation and troubleshooting

## 🔧 Scripts Available

| Script | Purpose | Environment | Use Case |
|--------|---------|-------------|----------|
| `setup-docker.sh` ⭐ | **Docker-based setup** | Docker | **Development/testing (recommended)** |
| `uninstall-docker.sh` | **Docker cleanup** | Docker | **Remove containers/volumes** |
| `setup.sh` | Full ELK Stack setup | K8s/OpenShift | Production/learning environment |
| `setup-local-cluster.sh` | Local cluster setup | Local K8s | Local development |
| `setup-lightweight.sh` | Minimal ELK setup | Any | Resource constrained environment |
| `uninstall.sh` | Complete K8s cleanup | K8s/OpenShift | Remove all K8s/OpenShift components |
| `test-scripts.sh` | **Validate all scripts** | Any | **Testing and validation** |

### 🚀 Quick Commands
```bash
# Start everything
./setup-docker.sh

# Validate setup
./test-scripts.sh

# Check status
docker-compose ps

# View logs
docker-compose logs -f kibana

# Stop everything
docker-compose down

# Complete cleanup
./uninstall-docker.sh
```

## 💡 Use Cases & Examples

### 🛍️ E-commerce Platform Monitoring
Real-world implementation dengan monitoring komprehensif:

**📊 Business Metrics:**
- **Order Processing** - Transaction volume, success rates
- **Customer Analytics** - User behavior, conversion tracking
- **Revenue Tracking** - Real-time sales monitoring

**🔧 Technical Monitoring:**
- **API Performance** - Response times, error rates
- **System Health** - CPU, memory, disk usage
- **Error Tracking** - Application errors and exceptions

**📈 Sample Dashboards:**
- Order processing pipeline visualization
- Real-time transaction monitoring
- Performance metrics and alerting
- Customer journey analytics

### 🎛️ Log Processing Pipeline
```
📱 Applications → 📡 Filebeat → 🚀 Kafka → ⚙️ Logstash → 🔍 Elasticsearch → 📊 Kibana
```

**Data Flow:**
1. **Collection**: Filebeat collects logs from applications
2. **Streaming**: Kafka handles real-time data streaming
3. **Processing**: Logstash parses, filters, and enriches data
4. **Storage**: Elasticsearch indexes and stores processed data
5. **Visualization**: Kibana creates dashboards and alerts

## 🛠️ Prerequisites

### 🐳 Docker Setup (Recommended)
- **Docker** 20.10+ & **Docker Compose** 2.0+
- **RAM**: 8GB minimum (12GB recommended)
- **Disk**: 20GB free space
- **OS**: Linux, macOS, Windows with WSL2

### ☸️ Kubernetes/OpenShift Setup
- **Cluster**: OpenShift 4.10+ or Kubernetes 1.24+
- **CLI Tools**: `oc` or `kubectl` installed and configured
- **Resources**: 16GB RAM, 50GB storage (cluster-wide)
- **Network**: Internet access for image downloads
- **Permissions**: Cluster admin or namespace admin rights

### 💻 System Requirements

| Component | Docker | Kubernetes |
|-----------|--------|------------|
| **CPU** | 4 cores | 8+ cores |
| **RAM** | 8GB | 16GB+ |
| **Disk** | 20GB | 50GB+ |
| **Network** | Localhost | Cluster network |

### 🔧 Quick Validation
```bash
# Check Docker
docker --version && docker-compose --version

# Check Kubernetes
kubectl version --client

# Check OpenShift
oc version --client

# Check available resources
free -h && df -h
```

## 🤝 Support & Troubleshooting

### 🆘 Common Issues & Solutions

**Docker Issues:**
```bash
# Elasticsearch won't start
sudo sysctl -w vm.max_map_count=262144

# Low memory error
docker-compose down && docker system prune -f

# Port conflicts
netstat -tulpn | grep :9200
```

**Service Issues:**
```bash
# Service not responding
docker-compose restart <service-name>

# Clear all data and restart
docker-compose down -v
./setup-docker.sh
```

**Access Issues:**
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs <service-name>

# Test connectivity
curl http://localhost:9200/_cluster/health
curl http://localhost:5601/api/status
```

**Resource Issues:**
```bash
# Check resource usage
docker stats

# Free up space
docker system prune -a -f

# Restart with more memory
docker-compose down
# Edit docker-compose.yml memory limits
docker-compose up -d
```

### 📚 Documentation & Help

1. **Hands-On Tutorial**: Follow [HANDS_ON_GUIDE.md](HANDS_ON_GUIDE.md) for complete step-by-step instructions
2. **Quick Reference**: Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for daily operations and commands
3. **Docker Setup**: Check [DOCKER_SETUP_GUIDE.md](DOCKER_SETUP_GUIDE.md) for Docker-specific setup
4. **Troubleshooting**: See [QUICK_START.md](QUICK_START.md) for common issues and solutions
5. **Complete Cleanup**: Use [UNINSTALL_GUIDE.md](UNINSTALL_GUIDE.md) for removal instructions

### 🔧 Debug Commands
```bash
# Health check all services
./test-scripts.sh

# View all logs
docker-compose logs

# Check specific service
docker-compose logs -f elasticsearch

# Check resource usage
docker stats

# Network connectivity test
docker-compose exec elasticsearch curl localhost:9200/_cluster/health

# Restart specific service
docker-compose restart kibana

# Access container shell
docker-compose exec elasticsearch bash
```

### 💬 Community Support
- **Issues**: GitHub repository issues
- **Discussions**: Community discussions tab
- **Documentation**: Wiki pages
- **Examples**: Sample configurations in each component folder

## 📚 Learning Path

### 👶 Beginner (Start Here)
1. **Read Overview**: Check this README for general understanding
2. **Complete Hands-On**: Follow [HANDS_ON_GUIDE.md](HANDS_ON_GUIDE.md) step by step
3. **Setup Docker Environment**: `./setup-docker.sh`
4. **Validate Installation**: `./test-scripts.sh`
5. **Use Quick Reference**: Bookmark [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for daily use

### 🔧 Intermediate 
1. **Study Architecture**: Understand the complete data flow pipeline
2. **Customize Configurations**: Modify Logstash pipelines and Elasticsearch mappings
3. **Create Custom Dashboards**: Build visualizations for your specific needs
4. **Practice with Real Data**: Use the sample applications and generate realistic logs
5. **Learn Advanced Queries**: Master Elasticsearch query DSL and KQL

### 🚀 Advanced
1. **Production Deployment**: Use `./setup.sh` for Kubernetes/OpenShift
2. **Security Configuration**: Implement authentication, authorization, and TLS
3. **Performance Tuning**: Optimize for high-volume production environments
4. **Custom Use Cases**: Adapt configurations for your organization's requirements
5. **Integration**: Connect with external monitoring and alerting systems

### 📈 Next Steps
- **Scale the Setup**: Add more nodes and services
- **Implement Security**: Add authentication, TLS, and role-based access
- **Custom Dashboards**: Create specific dashboards for your use cases
- **Alerting**: Set up monitoring alerts and notifications
- **Integration**: Connect with external systems and APIs

## 📄 License

This tutorial is provided under MIT License. See individual component licenses for OpenShift, Elasticsearch, Kafka, and related technologies.
