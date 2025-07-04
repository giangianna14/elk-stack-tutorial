# Quick Start Guide - ELK Stack Tutorial

## Pendahuluan
Panduan ini akan membantu Anda mempelajari implementasi ELK Stack dari OpenShift hingga Kibana dalam waktu singkat. Tutorial ini menggunakan contoh real-world dari industri e-commerce.

## Prerequisites

### Akses & Permissions
- [x] OpenShift cluster access dengan cluster-admin privileges
- [x] Minimum 16 vCPUs, 32GB RAM available di cluster
- [x] 500GB storage untuk persistent volumes
- [x] Network access ke external registries (docker.elastic.co, quay.io)

### Tools Required
```bash
# Install OpenShift CLI
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc kubectl /usr/local/bin/

# Verify installation
oc version
```

## 🚀 Quick Start 

### Step 1: Setup OpenShift Environment

**Option A: Use OpenShift Local (Recommended for Learning)**
```bash
# Download and install OpenShift Local (formerly CodeReady Containers)
# Visit: https://developers.redhat.com/products/openshift-local/overview
# Or download directly:
wget https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/2.32.0/crc-linux-amd64.tar.xz
tar -xf crc-linux-amd64.tar.xz
sudo mv crc-linux-*-amd64/crc /usr/local/bin/

# Setup OpenShift Local (requires 9GB RAM minimum)
crc setup
crc start

# Get login command
crc console --credentials

# Login to OpenShift
eval $(crc oc-env)
oc login -u kubeadmin -p <password-from-above> https://api.crc.testing:6443
```

**Option B: Use Existing OpenShift Cluster**
```bash
# Replace with your actual cluster URL
oc login https://api.your-cluster.com:6443
```

**Option C: Use Kubernetes with kubectl (Alternative)**
```bash
# If you have a Kubernetes cluster (minikube, kind, etc.)
kubectl cluster-info

# Verify connection
kubectl get nodes
```

### Step 2: Clone & Setup Tutorial
```bash
# Clone this repository
git clone https://github.com/your-repo/ELK-Tutorial
cd ELK-Tutorial

# For OpenShift: Run automated setup
./setup.sh

# For Kubernetes: Use kubectl version (to be created)
# ./setup-k8s.sh
```

### Step 2: Verify Deployment
```bash
# Check all components
oc get pods -n kafka
oc get pods -n elastic-system
oc get pods -n ecommerce-prod

# Get Kibana URL and credentials
oc get route kibana -n elastic-system
oc get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d
```

### Step 3: Access Kibana
1. Open Kibana URL in browser
2. Login with username: `elastic` and the password from step 2
3. Create index pattern: `logs-*`
4. Import dashboard templates from `06-kibana/dashboards/`

## 📚 Detailed Learning Path

### Phase 1: Understanding the Architecture (1 hour)
1. **Read Overview**: [README.md](./README.md)
2. **OpenShift Apps**: [01-openshift/README.md](./01-openshift/README.md)
3. **Beats Configuration**: [02-beats/README.md](./02-beats/README.md)

### Phase 2: Data Flow & Processing (2 hours)
4. **Kafka Integration**: [03-kafka/README.md](./03-kafka/README.md)
5. **Logstash Processing**: [04-logstash/README.md](./04-logstash/README.md)
6. **Elasticsearch Storage**: [05-elasticsearch/README.md](./05-elasticsearch/README.md)

### Phase 3: Visualization & Analytics (2 hours)
7. **Kibana Dashboards**: [06-kibana/README.md](./06-kibana/README.md)
8. **Real Use Cases**: [07-use-cases/ecommerce/README.md](./07-use-cases/ecommerce/README.md)

### Phase 4: Hands-on Practice (3+ hours)
9. **Configure Custom Pipelines**: Modify Logstash configurations
10. **Create Business Dashboards**: Build your own visualizations
11. **Setup Alerts**: Configure monitoring and alerting
12. **Performance Tuning**: Optimize for your use case

## 🎯 Key Learning Objectives

### Technical Skills
- [x] **Container Orchestration**: Deploy distributed systems on OpenShift
- [x] **Data Pipeline Design**: Build scalable log processing pipelines
- [x] **Search & Analytics**: Implement enterprise search solutions
- [x] **Monitoring & Alerting**: Set up proactive monitoring systems
- [x] **Security**: Implement RBAC and data protection

### Business Skills
- [x] **ROI Analysis**: Understand business value of observability
- [x] **Compliance**: Implement audit trails and compliance reporting
- [x] **Business Intelligence**: Create actionable business insights
- [x] **Cost Optimization**: Optimize infrastructure costs

## 📊 Real-World Scenarios

### 1. E-commerce Transaction Monitoring
**Time Required**: 45 minutes
**Location**: [07-use-cases/ecommerce/](./07-use-cases/ecommerce/)

**What You'll Learn**:
- Real-time revenue tracking
- Fraud detection patterns
- Customer journey analytics
- Compliance reporting (PCI-DSS)

### 2. Microservices Performance Monitoring
**Time Required**: 30 minutes
**Location**: [07-use-cases/microservices/](./07-use-cases/microservices/)

**What You'll Learn**:
- Service-to-service communication monitoring
- SLA tracking and alerting
- Distributed tracing correlation
- Capacity planning

### 3. Security Event Analysis (SIEM)
**Time Required**: 45 minutes
**Location**: [07-use-cases/security/](./07-use-cases/security/)

**What You'll Learn**:
- Security event correlation
- Threat detection and response
- Compliance audit trails
- Incident investigation workflows

## 🛠 Troubleshooting Guide

### Common Issues

#### Pods Stuck in Pending State
```bash
# Check resource constraints
oc describe node
oc get events --sort-by=.metadata.creationTimestamp

# Check storage
oc get pv
oc get pvc -A
```

#### Elasticsearch Yellow/Red Status
```bash
# Check cluster health
oc exec -it elasticsearch-es-master-0 -n elastic-system -- curl -k -u elastic:$PASSWORD https://localhost:9200/_cluster/health?pretty

# Check indices status
oc exec -it elasticsearch-es-master-0 -n elastic-system -- curl -k -u elastic:$PASSWORD https://localhost:9200/_cat/indices?v
```

#### Kafka Connection Issues
```bash
# Check Kafka cluster status
oc get kafka kafka-cluster -n kafka -o yaml

# Test connectivity
oc run kafka-test --image=quay.io/strimzi/kafka:latest-kafka-3.6.0 --rm -it --restart=Never -- /bin/bash
# Inside container:
bin/kafka-console-producer.sh --bootstrap-server kafka-cluster-kafka-bootstrap:9092 --topic test
```

#### Filebeat Not Collecting Logs
```bash
# Check DaemonSet status
oc get daemonset filebeat -n elastic-system

# Check logs
oc logs daemonset/filebeat -n elastic-system

# Check configuration
oc get configmap filebeat-config -n elastic-system -o yaml
```

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] OpenShift cluster access verified
- [ ] Sufficient resources available
- [ ] Network policies configured
- [ ] Storage classes available
- [ ] DNS resolution working

### Kafka Deployment
- [ ] Strimzi operator installed
- [ ] Kafka cluster deployed (3 brokers)
- [ ] Topics created and configured
- [ ] Users and ACLs configured
- [ ] Monitoring enabled

### Elasticsearch Deployment
- [ ] ECK operator installed
- [ ] Master nodes deployed (3 nodes)
- [ ] Data nodes deployed (3+ nodes)
- [ ] Index templates configured
- [ ] ILM policies created
- [ ] Security configured

### Logstash Deployment
- [ ] Pipeline configurations created
- [ ] Input/output plugins configured
- [ ] Filters and processors setup
- [ ] Performance tuning applied
- [ ] Monitoring enabled

### Kibana Deployment
- [ ] Kibana pods running
- [ ] Index patterns created
- [ ] Dashboards imported
- [ ] User roles configured
- [ ] Alerting rules setup

### Filebeat Deployment
- [ ] DaemonSet deployed on all nodes
- [ ] Autodiscovery configured
- [ ] Field enrichment working
- [ ] Output to Kafka verified
- [ ] Log parsing working

### Application Deployment
- [ ] Sample applications deployed
- [ ] Logging configuration applied
- [ ] Structured logging implemented
- [ ] Business metrics embedded
- [ ] Health checks configured

## 📈 Performance Benchmarks

### Expected Performance (Reference Environment)
- **Log Ingestion**: 50,000 events/second
- **Search Latency**: <200ms (95th percentile)
- **Dashboard Load Time**: <3 seconds
- **Storage Efficiency**: 70% compression ratio
- **Resource Usage**: 60% CPU, 80% memory during peak

### Optimization Tips
1. **Index Management**: Use time-based indices with proper rollover
2. **Shard Strategy**: 1-2 shards per node for hot indices
3. **Batch Size**: Optimize Logstash batch sizes for throughput
4. **Caching**: Enable query caching in Elasticsearch
5. **Hardware**: Use SSD storage for hot data

## 🎓 Advanced Topics

### For Further Learning
- **Custom Processors**: Build custom Logstash filters
- **Machine Learning**: Implement anomaly detection
- **Cross-Cluster Replication**: Setup disaster recovery
- **Custom Visualizations**: Build Kibana plugins
- **Integration**: Connect with external systems (SIEM, ITSM)

## 📞 Support & Community

### Getting Help
- **Documentation**: Each component has detailed README files
- **Examples**: Complete working examples in use-cases directory
- **Issues**: Check common issues in troubleshooting section
- **Community**: Join Elastic community forums

### Contributing
- **Bug Reports**: Open issues with detailed reproduction steps
- **Feature Requests**: Describe use cases and business value
- **Pull Requests**: Include tests and documentation
- **Documentation**: Help improve tutorials and examples

---

**Time Investment**: 8-12 hours for complete tutorial
**Prerequisites**: Basic Kubernetes/OpenShift knowledge
**Outcome**: Production-ready ELK stack with real-world use cases
