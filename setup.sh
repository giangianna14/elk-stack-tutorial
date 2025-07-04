#!/bin/bash

# ELK Stack Tutorial - Complete Setup Script
# This script sets up the entire ELK stack on OpenShift
# Author: ELK Tutorial Team
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE_KAFKA="kafka"
NAMESPACE_ELASTIC="elastic-system"
NAMESPACE_APPS="ecommerce-prod"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}  ELK Stack Tutorial Setup${NC}"
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
    
    # Check if oc CLI is available
    if ! command -v oc &> /dev/null; then
        print_error "OpenShift CLI (oc) is not installed or not in PATH"
        exit 1
    fi
    
    # Check if logged in to OpenShift
    if ! oc whoami &> /dev/null; then
        print_error "Not logged in to OpenShift. Please run 'oc login' first"
        exit 1
    fi
    
    # Check cluster admin permissions
    if ! oc auth can-i create clusterrole &> /dev/null; then
        print_warning "You may not have cluster admin permissions. Some operations might fail."
    fi
    
    print_status "Prerequisites check completed ✓"
}

# Create namespaces
create_namespaces() {
    print_status "Creating namespaces..."
    
    oc create namespace $NAMESPACE_KAFKA --dry-run=client -o yaml | oc apply -f -
    oc create namespace $NAMESPACE_ELASTIC --dry-run=client -o yaml | oc apply -f -
    oc create namespace $NAMESPACE_APPS --dry-run=client -o yaml | oc apply -f -
    
    # Label namespaces
    oc label namespace $NAMESPACE_KAFKA name=$NAMESPACE_KAFKA --overwrite
    oc label namespace $NAMESPACE_ELASTIC name=$NAMESPACE_ELASTIC --overwrite
    oc label namespace $NAMESPACE_APPS name=$NAMESPACE_APPS --overwrite
    
    print_status "Namespaces created ✓"
}

# Install Strimzi Operator for Kafka
install_strimzi_operator() {
    print_status "Installing Strimzi Kafka Operator..."
    
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: strimzi-kafka-operator
  namespace: openshift-operators
spec:
  channel: stable
  name: strimzi-kafka-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
    
    # Wait for operator to be ready
    print_status "Waiting for Strimzi operator to be ready..."
    oc wait --for=condition=ready pod -l name=strimzi-cluster-operator -n openshift-operators --timeout=300s
    
    print_status "Strimzi Operator installed ✓"
}

# Install ECK Operator for Elasticsearch
install_eck_operator() {
    print_status "Installing Elastic Cloud on Kubernetes (ECK) Operator..."
    
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: elastic-cloud-eck
  namespace: openshift-operators
spec:
  channel: stable
  name: elastic-cloud-eck
  source: certified-operators
  sourceNamespace: openshift-marketplace
EOF
    
    # Wait for operator to be ready
    print_status "Waiting for ECK operator to be ready..."
    oc wait --for=condition=ready pod -l control-plane=elastic-operator -n openshift-operators --timeout=300s
    
    print_status "ECK Operator installed ✓"
}

# Deploy Kafka Cluster
deploy_kafka() {
    print_status "Deploying Kafka cluster..."
    
    # Apply the Kafka cluster configuration
    oc apply -f 03-kafka/cluster-setup/kafka-cluster.yaml -n $NAMESPACE_KAFKA
    
    # Wait for Kafka to be ready
    print_status "Waiting for Kafka cluster to be ready (this may take 5-10 minutes)..."
    oc wait kafka/kafka-cluster --for=condition=Ready --timeout=600s -n $NAMESPACE_KAFKA
    
    print_status "Kafka cluster deployed ✓"
}

# Deploy Elasticsearch
deploy_elasticsearch() {
    print_status "Deploying Elasticsearch cluster..."
    
    cat <<EOF | oc apply -f - -n $NAMESPACE_ELASTIC
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
spec:
  version: 8.14.1
  nodeSets:
  - name: master
    count: 3
    config:
      node.store.allow_mmap: false
      node.roles: ["master"]
      xpack.security.enabled: true
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 2Gi
              cpu: 1
            limits:
              memory: 4Gi
              cpu: 2
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms2g -Xmx2g"
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
  - name: data
    count: 3
    config:
      node.store.allow_mmap: false
      node.roles: ["data", "ingest"]
      xpack.security.enabled: true
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 4Gi
              cpu: 2
            limits:
              memory: 8Gi
              cpu: 4
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms4g -Xmx4g"
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
EOF
    
    # Wait for Elasticsearch to be ready
    print_status "Waiting for Elasticsearch cluster to be ready (this may take 10-15 minutes)..."
    oc wait elasticsearch/elasticsearch --for=condition=Ready --timeout=900s -n $NAMESPACE_ELASTIC
    
    print_status "Elasticsearch cluster deployed ✓"
}

# Deploy Kibana
deploy_kibana() {
    print_status "Deploying Kibana..."
    
    cat <<EOF | oc apply -f - -n $NAMESPACE_ELASTIC
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
spec:
  version: 8.14.1
  count: 2
  elasticsearchRef:
    name: elasticsearch
  config:
    server.publicBaseUrl: "https://kibana-$NAMESPACE_ELASTIC.apps.$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})"
    xpack.fleet.agents.elasticsearch.hosts: ["https://elasticsearch-es-http.elastic-system.svc:9200"]
    xpack.fleet.agents.fleet_server.hosts: ["https://fleet-server-agent-http.elastic-system.svc:8220"]
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1
EOF
    
    # Create route for Kibana
    oc create route edge kibana --service=kibana-kb-http --port=5601 -n $NAMESPACE_ELASTIC || true
    
    # Wait for Kibana to be ready
    print_status "Waiting for Kibana to be ready..."
    oc wait kibana/kibana --for=condition=Ready --timeout=600s -n $NAMESPACE_ELASTIC
    
    print_status "Kibana deployed ✓"
}

# Deploy Logstash
deploy_logstash() {
    print_status "Deploying Logstash..."
    
    # Create Logstash configuration
    cat <<EOF | oc apply -f - -n $NAMESPACE_ELASTIC
apiVersion: v1
kind: ConfigMap
metadata:
  name: logstash-config
data:
  logstash.yml: |
    http.host: "0.0.0.0"
    path.config: /usr/share/logstash/pipeline
    xpack.monitoring.enabled: true
    xpack.monitoring.elasticsearch.hosts: ["https://elasticsearch-es-http:9200"]
    xpack.monitoring.elasticsearch.username: "elastic"
    xpack.monitoring.elasticsearch.password: "\${ELASTICSEARCH_PASSWORD}"
    xpack.monitoring.elasticsearch.ssl.certificate_authority: "/etc/ssl/certs/elasticsearch-ca.crt"
  pipelines.yml: |
    - pipeline.id: applications
      path.config: "/usr/share/logstash/pipeline/applications.conf"
    - pipeline.id: security
      path.config: "/usr/share/logstash/pipeline/security.conf"
    - pipeline.id: business
      path.config: "/usr/share/logstash/pipeline/business.conf"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: logstash
  labels:
    app: logstash
spec:
  replicas: 3
  selector:
    matchLabels:
      app: logstash
  template:
    metadata:
      labels:
        app: logstash
    spec:
      containers:
      - name: logstash
        image: docker.elastic.co/logstash/logstash:8.14.1
        ports:
        - containerPort: 9600
          name: http
        - containerPort: 5044
          name: beats
        env:
        - name: ELASTICSEARCH_PASSWORD
          valueFrom:
            secretKeyRef:
              name: elasticsearch-es-elastic-user
              key: elastic
        resources:
          requests:
            memory: 2Gi
            cpu: 1
          limits:
            memory: 4Gi
            cpu: 2
        volumeMounts:
        - name: config
          mountPath: /usr/share/logstash/config/logstash.yml
          subPath: logstash.yml
        - name: config
          mountPath: /usr/share/logstash/config/pipelines.yml
          subPath: pipelines.yml
        - name: pipeline-config
          mountPath: /usr/share/logstash/pipeline
        - name: ca-certs
          mountPath: /etc/ssl/certs/elasticsearch-ca.crt
          subPath: ca.crt
      volumes:
      - name: config
        configMap:
          name: logstash-config
      - name: pipeline-config
        configMap:
          name: logstash-pipeline
      - name: ca-certs
        secret:
          secretName: elasticsearch-es-http-certs-public
---
apiVersion: v1
kind: Service
metadata:
  name: logstash
  labels:
    app: logstash
spec:
  ports:
  - port: 9600
    targetPort: 9600
    name: http
  - port: 5044
    targetPort: 5044
    name: beats
  selector:
    app: logstash
EOF
    
    print_status "Logstash deployed ✓"
}

# Deploy Filebeat
deploy_filebeat() {
    print_status "Deploying Filebeat..."
    
    oc apply -f 02-beats/filebeat/filebeat-daemonset.yaml
    
    # Wait for Filebeat to be ready
    print_status "Waiting for Filebeat DaemonSet to be ready..."
    oc rollout status daemonset/filebeat -n $NAMESPACE_ELASTIC --timeout=300s
    
    print_status "Filebeat deployed ✓"
}

# Deploy sample applications
deploy_sample_apps() {
    print_status "Deploying sample e-commerce applications..."
    
    oc apply -f 01-openshift/sample-apps/ -n $NAMESPACE_APPS
    
    print_status "Sample applications deployed ✓"
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    # Get Kibana URL
    KIBANA_URL=$(oc get route kibana -n $NAMESPACE_ELASTIC -o jsonpath='{.spec.host}' 2>/dev/null || echo "No route found")
    
    # Get Elasticsearch password
    ES_PASSWORD=$(oc get secret elasticsearch-es-elastic-user -n $NAMESPACE_ELASTIC -o jsonpath='{.data.elastic}' | base64 -d 2>/dev/null || echo "Not available")
    
    echo
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}    Setup Completed Successfully!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "Kibana URL: ${GREEN}https://$KIBANA_URL${NC}"
    echo -e "Username: ${GREEN}elastic${NC}"
    echo -e "Password: ${GREEN}$ES_PASSWORD${NC}"
    echo
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "Check Kafka status: ${YELLOW}oc get kafka -n $NAMESPACE_KAFKA${NC}"
    echo -e "Check Elasticsearch: ${YELLOW}oc get elasticsearch -n $NAMESPACE_ELASTIC${NC}"
    echo -e "Check Kibana: ${YELLOW}oc get kibana -n $NAMESPACE_ELASTIC${NC}"
    echo -e "View logs: ${YELLOW}oc logs -f daemonset/filebeat -n $NAMESPACE_ELASTIC${NC}"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Access Kibana dashboard"
    echo "2. Create index patterns for logs-*"
    echo "3. Import dashboard templates from 06-kibana/dashboards/"
    echo "4. Configure alerts in 06-kibana/alerting/"
    echo
}

# Main execution
main() {
    check_prerequisites
    create_namespaces
    install_strimzi_operator
    install_eck_operator
    deploy_kafka
    deploy_elasticsearch
    deploy_kibana
    deploy_logstash
    deploy_filebeat
    deploy_sample_apps
    get_access_info
}

# Run main function
main "$@"
