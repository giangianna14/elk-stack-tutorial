#!/bin/bash

# ELK Stack Tutorial - Lightweight Setup Script
# This script sets up a minimal ELK stack for learning purposes on resource-constrained environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE_ELASTIC="elastic-system"
NAMESPACE_APPS="demo-apps"

echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE}  ELK Stack - Lightweight Setup${NC}"
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
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if connected to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Not connected to a Kubernetes cluster. Please run './setup-local-cluster.sh' first"
        exit 1
    fi
    
    # Check available resources
    total_nodes=$(kubectl get nodes --no-headers | wc -l)
    print_status "Connected to cluster with $total_nodes node(s)"
    
    print_status "Prerequisites check completed ✓"
}

# Create namespaces
create_namespaces() {
    print_status "Creating namespaces..."
    
    kubectl create namespace $NAMESPACE_ELASTIC --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace $NAMESPACE_APPS --dry-run=client -o yaml | kubectl apply -f -
    
    print_status "Namespaces created ✓"
}

# Deploy single-node Elasticsearch
deploy_elasticsearch() {
    print_status "Deploying lightweight Elasticsearch..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: $NAMESPACE_ELASTIC
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:8.14.1
        ports:
        - containerPort: 9200
        - containerPort: 9300
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms1g -Xmx1g"
        - name: xpack.security.enabled
          value: "false"
        - name: xpack.security.enrollment.enabled
          value: "false"
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1000m
        volumeMounts:
        - name: data
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: $NAMESPACE_ELASTIC
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
  type: ClusterIP
EOF
    
    print_status "Waiting for Elasticsearch to be ready..."
    kubectl wait --for=condition=ready pod -l app=elasticsearch -n $NAMESPACE_ELASTIC --timeout=300s
    
    print_status "Elasticsearch deployed ✓"
}

# Deploy Kibana
deploy_kibana() {
    print_status "Deploying Kibana..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: $NAMESPACE_ELASTIC
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:8.14.1
        ports:
        - containerPort: 5601
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
        - name: xpack.security.enabled
          value: "false"
        - name: xpack.encryptedSavedObjects.encryptionKey
          value: "something_at_least_32_characters_long"
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: kibana
  namespace: $NAMESPACE_ELASTIC
spec:
  selector:
    app: kibana
  ports:
  - port: 5601
    targetPort: 5601
    nodePort: 30001
  type: NodePort
EOF
    
    print_status "Waiting for Kibana to be ready..."
    kubectl wait --for=condition=ready pod -l app=kibana -n $NAMESPACE_ELASTIC --timeout=300s
    
    print_status "Kibana deployed ✓"
}

# Deploy Filebeat
deploy_filebeat() {
    print_status "Deploying Filebeat..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: $NAMESPACE_ELASTIC
data:
  filebeat.yml: |
    filebeat.inputs:
    - type: container
      paths:
        - /var/log/containers/*.log
      processors:
        - add_kubernetes_metadata:
            host: \${NODE_NAME}
            matchers:
            - logs_path:
                logs_path: "/var/log/containers/"
    
    output.elasticsearch:
      hosts: ["elasticsearch:9200"]
      index: "filebeat-%{+yyyy.MM.dd}"
    
    setup.template.settings:
      index.number_of_shards: 1
      index.number_of_replicas: 0
    
    setup.kibana:
      host: "kibana:5601"
    
    logging.level: info
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: filebeat
  namespace: $NAMESPACE_ELASTIC
spec:
  selector:
    matchLabels:
      app: filebeat
  template:
    metadata:
      labels:
        app: filebeat
    spec:
      serviceAccountName: filebeat
      containers:
      - name: filebeat
        image: docker.elastic.co/beats/filebeat:8.14.1
        args: [
          "-c", "/etc/filebeat.yml",
          "-e",
        ]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        securityContext:
          runAsUser: 0
        resources:
          requests:
            memory: 100Mi
            cpu: 100m
          limits:
            memory: 200Mi
            cpu: 200m
        volumeMounts:
        - name: config
          mountPath: /etc/filebeat.yml
          subPath: filebeat.yml
        - name: data
          mountPath: /usr/share/filebeat/data
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: varlog
          mountPath: /var/log
          readOnly: true
      volumes:
      - name: config
        configMap:
          defaultMode: 0600
          name: filebeat-config
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: varlog
        hostPath:
          path: /var/log
      - name: data
        hostPath:
          path: /var/lib/filebeat-data
          type: DirectoryOrCreate
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: $NAMESPACE_ELASTIC
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
- apiGroups: [""]
  resources:
  - nodes
  - namespaces
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: $NAMESPACE_ELASTIC
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
EOF
    
    print_status "Filebeat deployed ✓"
}

# Deploy sample application
deploy_sample_app() {
    print_status "Deploying sample application..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: $NAMESPACE_APPS
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
      - name: sample-app
        image: nginx:alpine
        ports:
        - containerPort: 80
        command: ["/bin/sh"]
        args:
        - -c
        - |
          while true; do
            echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\",\"service\":\"sample-app\",\"level\":\"INFO\",\"message\":\"Sample log message\",\"request_id\":\"req_$RANDOM\",\"user_id\":\"user_$((RANDOM % 1000))\",\"action\":\"page_view\",\"duration\":$((RANDOM % 1000))}" >> /var/log/sample-app.log
            sleep 5
          done &
          nginx -g 'daemon off;'
        resources:
          requests:
            memory: 64Mi
            cpu: 50m
          limits:
            memory: 128Mi
            cpu: 100m
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: $NAMESPACE_APPS
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30002
  type: NodePort
EOF
    
    print_status "Sample application deployed ✓"
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    # Get cluster info
    CLUSTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
    
    # For minikube, get the actual IP
    if command -v minikube &> /dev/null && minikube status &> /dev/null; then
        CLUSTER_IP=$(minikube ip)
    fi
    
    echo
    echo -e "${GREEN}=================================${NC}"
    echo -e "${GREEN}    Setup Completed Successfully!${NC}"
    echo -e "${GREEN}=================================${NC}"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "Kibana URL: ${GREEN}http://$CLUSTER_IP:30001${NC}"
    echo -e "Sample App: ${GREEN}http://$CLUSTER_IP:30002${NC}"
    echo -e "Username: ${GREEN}No authentication required${NC}"
    echo
    echo -e "${BLUE}Useful Commands:${NC}"
    echo -e "Check Elasticsearch: ${YELLOW}kubectl get pods -n $NAMESPACE_ELASTIC${NC}"
    echo -e "Check sample app: ${YELLOW}kubectl get pods -n $NAMESPACE_APPS${NC}"
    echo -e "View Filebeat logs: ${YELLOW}kubectl logs -f daemonset/filebeat -n $NAMESPACE_ELASTIC${NC}"
    echo -e "Port forward Kibana: ${YELLOW}kubectl port-forward svc/kibana 5601:5601 -n $NAMESPACE_ELASTIC${NC}"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Access Kibana at the URL above"
    echo "2. Create index pattern: filebeat-*"
    echo "3. Explore the sample application logs"
    echo "4. Try the advanced features in the full tutorial"
    echo
    echo -e "${YELLOW}Note: This is a lightweight setup for learning purposes.${NC}"
    echo -e "${YELLOW}For production use, follow the full tutorial with proper security.${NC}"
}

# Main execution
main() {
    check_prerequisites
    create_namespaces
    deploy_elasticsearch
    deploy_kibana
    deploy_filebeat
    deploy_sample_app
    get_access_info
}

# Run main function
main "$@"
