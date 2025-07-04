#!/bin/bash

# ELK Stack Tutorial - Complete Uninstall Script
# This script removes all ELK stack components and cleans up resources

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
NAMESPACE_DEMO="demo-apps"

echo -e "${RED}=======================================${NC}"
echo -e "${RED}  ELK Stack Tutorial - UNINSTALL${NC}"
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

# Check if we're in OpenShift or Kubernetes
check_environment() {
    if command -v oc &> /dev/null && oc whoami &> /dev/null; then
        PLATFORM="openshift"
        CLI_CMD="oc"
        print_status "Detected OpenShift environment"
    elif command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
        PLATFORM="kubernetes"
        CLI_CMD="kubectl"
        print_status "Detected Kubernetes environment"
    else
        print_error "Not connected to any cluster. Nothing to uninstall."
        exit 1
    fi
}

# Show what will be deleted
show_warning() {
    echo -e "${RED}⚠️  WARNING: This will completely remove all ELK stack components! ⚠️${NC}"
    echo
    echo -e "${YELLOW}The following will be deleted:${NC}"
    echo "📦 Namespaces:"
    echo "   - $NAMESPACE_KAFKA (Kafka cluster)"
    echo "   - $NAMESPACE_ELASTIC (Elasticsearch, Kibana, Logstash, Filebeat)"
    echo "   - $NAMESPACE_APPS (Sample applications)"
    echo "   - $NAMESPACE_DEMO (Demo applications)"
    echo
    echo "🔧 Operators:"
    echo "   - Strimzi Kafka Operator"
    echo "   - Elastic Cloud on Kubernetes (ECK) Operator"
    echo
    echo "💾 Data:"
    echo "   - All log data in Elasticsearch"
    echo "   - All Kafka topics and messages"
    echo "   - All persistent volumes"
    echo "   - All dashboards and configurations"
    echo
    echo "🔐 RBAC Resources:"
    echo "   - Service accounts, roles, and bindings"
    echo "   - Custom resource definitions"
    echo
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Uninstall cancelled."
        exit 0
    fi
}

# Remove applications
remove_applications() {
    print_status "Removing sample applications..."
    
    # Remove demo applications
    if $CLI_CMD get namespace $NAMESPACE_DEMO &> /dev/null; then
        print_status "Removing demo applications..."
        $CLI_CMD delete namespace $NAMESPACE_DEMO --grace-period=0 --force 2>/dev/null || true
    fi
    
    # Remove e-commerce applications
    if $CLI_CMD get namespace $NAMESPACE_APPS &> /dev/null; then
        print_status "Removing e-commerce applications..."
        $CLI_CMD delete namespace $NAMESPACE_APPS --grace-period=0 --force 2>/dev/null || true
    fi
    
    print_status "Applications removed ✓"
}

# Remove Filebeat
remove_filebeat() {
    print_status "Removing Filebeat..."
    
    # Remove Filebeat DaemonSet and related resources
    $CLI_CMD delete daemonset filebeat -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
    $CLI_CMD delete configmap filebeat-config -n $NAMESPACE_ELASTIC 2>/dev/null || true
    $CLI_CMD delete serviceaccount filebeat -n $NAMESPACE_ELASTIC 2>/dev/null || true
    $CLI_CMD delete clusterrole filebeat 2>/dev/null || true
    $CLI_CMD delete clusterrolebinding filebeat 2>/dev/null || true
    
    print_status "Filebeat removed ✓"
}

# Remove Logstash
remove_logstash() {
    print_status "Removing Logstash..."
    
    # Remove Logstash deployment and related resources
    $CLI_CMD delete deployment logstash -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
    $CLI_CMD delete service logstash -n $NAMESPACE_ELASTIC 2>/dev/null || true
    $CLI_CMD delete configmap logstash-config -n $NAMESPACE_ELASTIC 2>/dev/null || true
    $CLI_CMD delete configmap logstash-pipeline -n $NAMESPACE_ELASTIC 2>/dev/null || true
    
    print_status "Logstash removed ✓"
}

# Remove Kibana
remove_kibana() {
    print_status "Removing Kibana..."
    
    if [ "$PLATFORM" = "openshift" ]; then
        # Remove OpenShift Kibana (ECK)
        $CLI_CMD delete kibana kibana -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete route kibana -n $NAMESPACE_ELASTIC 2>/dev/null || true
    else
        # Remove Kubernetes Kibana
        $CLI_CMD delete deployment kibana -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete service kibana -n $NAMESPACE_ELASTIC 2>/dev/null || true
    fi
    
    print_status "Kibana removed ✓"
}

# Remove Elasticsearch
remove_elasticsearch() {
    print_status "Removing Elasticsearch..."
    
    if [ "$PLATFORM" = "openshift" ]; then
        # Remove OpenShift Elasticsearch (ECK)
        $CLI_CMD delete elasticsearch elasticsearch -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
        
        # Remove ECK secrets
        $CLI_CMD delete secret elasticsearch-es-elastic-user -n $NAMESPACE_ELASTIC 2>/dev/null || true
        $CLI_CMD delete secret elasticsearch-es-http-certs-public -n $NAMESPACE_ELASTIC 2>/dev/null || true
        $CLI_CMD delete secret elasticsearch-es-http-certs-internal -n $NAMESPACE_ELASTIC 2>/dev/null || true
        $CLI_CMD delete secret elasticsearch-es-transport-certs -n $NAMESPACE_ELASTIC 2>/dev/null || true
    else
        # Remove Kubernetes Elasticsearch
        $CLI_CMD delete deployment elasticsearch -n $NAMESPACE_ELASTIC --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete service elasticsearch -n $NAMESPACE_ELASTIC 2>/dev/null || true
    fi
    
    print_status "Elasticsearch removed ✓"
}

# Remove Kafka
remove_kafka() {
    print_status "Removing Kafka cluster..."
    
    if $CLI_CMD get namespace $NAMESPACE_KAFKA &> /dev/null; then
        # Remove Kafka users
        $CLI_CMD delete kafkauser --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        
        # Remove Kafka topics
        $CLI_CMD delete kafkatopic --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        
        # Remove Kafka cluster
        $CLI_CMD delete kafka kafka-cluster -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        
        # Remove Kafka Connect and other resources
        $CLI_CMD delete kafkaconnect --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete kafkabridge --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete kafkamirrormaker --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        $CLI_CMD delete kafkamirrormaker2 --all -n $NAMESPACE_KAFKA --grace-period=0 --force 2>/dev/null || true
        
        # Remove ConfigMaps
        $CLI_CMD delete configmap kafka-metrics -n $NAMESPACE_KAFKA 2>/dev/null || true
        
        print_status "Kafka cluster removed ✓"
    fi
}

# Remove operators
remove_operators() {
    print_status "Removing operators..."
    
    if [ "$PLATFORM" = "openshift" ]; then
        # Remove ECK Operator subscription
        $CLI_CMD delete subscription elastic-cloud-eck -n openshift-operators 2>/dev/null || true
        
        # Remove Strimzi Operator subscription
        $CLI_CMD delete subscription strimzi-kafka-operator -n openshift-operators 2>/dev/null || true
        
        # Remove operator CSVs
        $CLI_CMD delete csv -l operators.coreos.com/elastic-cloud-eck.openshift-operators -n openshift-operators 2>/dev/null || true
        $CLI_CMD delete csv -l operators.coreos.com/strimzi-kafka-operator.openshift-operators -n openshift-operators 2>/dev/null || true
    else
        # Remove ECK Operator (if installed via manifests)
        $CLI_CMD delete -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml 2>/dev/null || true
        $CLI_CMD delete -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml 2>/dev/null || true
        
        # Remove Strimzi Operator (if installed via manifests)
        $CLI_CMD delete -f https://strimzi.io/install/latest?namespace=kafka 2>/dev/null || true
    fi
    
    print_status "Operators removed ✓"
}

# Remove Custom Resource Definitions
remove_crds() {
    print_status "Removing Custom Resource Definitions..."
    
    # Remove Elastic CRDs
    $CLI_CMD delete crd elasticsearches.elasticsearch.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd kibanas.kibana.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd apmservers.apm.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd enterprisesearches.enterprisesearch.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd beats.beat.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd elasticmapsservers.maps.k8s.elastic.co 2>/dev/null || true
    $CLI_CMD delete crd agents.agent.k8s.elastic.co 2>/dev/null || true
    
    # Remove Strimzi CRDs
    $CLI_CMD delete crd kafkas.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkaconnects.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkatopics.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkausers.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkaconnectors.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkamirrormakers.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkabridges.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkamirrormaker2s.kafka.strimzi.io 2>/dev/null || true
    $CLI_CMD delete crd kafkarebalances.kafka.strimzi.io 2>/dev/null || true
    
    print_status "Custom Resource Definitions removed ✓"
}

# Remove persistent volumes
remove_persistent_volumes() {
    print_status "Removing persistent volumes..."
    
    # Remove PVCs from all namespaces
    $CLI_CMD delete pvc --all -n $NAMESPACE_KAFKA 2>/dev/null || true
    $CLI_CMD delete pvc --all -n $NAMESPACE_ELASTIC 2>/dev/null || true
    $CLI_CMD delete pvc --all -n $NAMESPACE_APPS 2>/dev/null || true
    $CLI_CMD delete pvc --all -n $NAMESPACE_DEMO 2>/dev/null || true
    
    # Remove orphaned PVs (be careful with this)
    print_warning "Checking for orphaned persistent volumes..."
    orphaned_pvs=$($CLI_CMD get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="'$NAMESPACE_KAFKA'")].metadata.name}' 2>/dev/null || true)
    if [ -n "$orphaned_pvs" ]; then
        echo "Found orphaned PVs: $orphaned_pvs"
        for pv in $orphaned_pvs; do
            $CLI_CMD delete pv $pv --grace-period=0 --force 2>/dev/null || true
        done
    fi
    
    print_status "Persistent volumes removed ✓"
}

# Remove namespaces
remove_namespaces() {
    print_status "Removing namespaces..."
    
    # Remove namespaces in order
    for ns in $NAMESPACE_APPS $NAMESPACE_DEMO $NAMESPACE_ELASTIC $NAMESPACE_KAFKA; do
        if $CLI_CMD get namespace $ns &> /dev/null; then
            print_status "Removing namespace: $ns"
            $CLI_CMD delete namespace $ns --grace-period=0 --force 2>/dev/null || true
            
            # Wait for namespace to be fully deleted
            print_status "Waiting for namespace $ns to be deleted..."
            timeout=60
            while [ $timeout -gt 0 ] && $CLI_CMD get namespace $ns &> /dev/null; do
                sleep 2
                timeout=$((timeout - 2))
                echo -n "."
            done
            echo
        fi
    done
    
    print_status "Namespaces removed ✓"
}

# Clean up local cluster if running
cleanup_local_cluster() {
    print_status "Checking for local cluster cleanup..."
    
    # Check if CRC is running
    if command -v crc &> /dev/null; then
        crc_status=$(crc status 2>/dev/null | grep "CRC VM" | awk '{print $3}' || echo "Unknown")
        if [ "$crc_status" = "Running" ]; then
            echo
            read -p "OpenShift Local (CRC) is running. Do you want to stop it? (y/N): " stop_crc
            if [[ $stop_crc =~ ^[Yy]$ ]]; then
                print_status "Stopping OpenShift Local..."
                crc stop
                print_status "OpenShift Local stopped ✓"
            fi
        fi
    fi
    
    # Check if Minikube is running
    if command -v minikube &> /dev/null; then
        if minikube status &> /dev/null; then
            echo
            read -p "Minikube is running. Do you want to stop it? (y/N): " stop_minikube
            if [[ $stop_minikube =~ ^[Yy]$ ]]; then
                print_status "Stopping Minikube..."
                minikube stop
                print_status "Minikube stopped ✓"
            fi
        fi
    fi
    
    # Check if Kind clusters exist
    if command -v kind &> /dev/null; then
        kind_clusters=$(kind get clusters 2>/dev/null || echo "")
        if [ -n "$kind_clusters" ]; then
            echo
            echo "Found Kind clusters: $kind_clusters"
            read -p "Do you want to delete Kind clusters? (y/N): " delete_kind
            if [[ $delete_kind =~ ^[Yy]$ ]]; then
                for cluster in $kind_clusters; do
                    print_status "Deleting Kind cluster: $cluster"
                    kind delete cluster --name $cluster
                done
                print_status "Kind clusters deleted ✓"
            fi
        fi
    fi
}

# Verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check if namespaces are gone
    remaining_ns=""
    for ns in $NAMESPACE_KAFKA $NAMESPACE_ELASTIC $NAMESPACE_APPS $NAMESPACE_DEMO; do
        if $CLI_CMD get namespace $ns &> /dev/null; then
            remaining_ns="$remaining_ns $ns"
        fi
    done
    
    if [ -n "$remaining_ns" ]; then
        print_warning "Some namespaces still exist: $remaining_ns"
        print_warning "They may be stuck in 'Terminating' state. This is normal and they will be cleaned up eventually."
    fi
    
    # Check for remaining CRDs
    elastic_crds=$($CLI_CMD get crd | grep -E "(elastic|kibana)" | wc -l || echo "0")
    kafka_crds=$($CLI_CMD get crd | grep -E "kafka" | wc -l || echo "0")
    
    if [ "$elastic_crds" -gt 0 ] || [ "$kafka_crds" -gt 0 ]; then
        print_warning "Some Custom Resource Definitions may still exist:"
        $CLI_CMD get crd | grep -E "(elastic|kibana|kafka)" || true
    fi
    
    print_status "Cleanup verification completed ✓"
}

# Main execution
main() {
    check_environment
    show_warning
    
    print_status "Starting ELK Stack uninstall..."
    
    # Remove components in reverse order
    remove_applications
    remove_filebeat
    remove_logstash
    remove_kibana
    remove_elasticsearch
    remove_kafka
    remove_persistent_volumes
    remove_namespaces
    remove_operators
    remove_crds
    
    # Optional: cleanup local cluster
    cleanup_local_cluster
    
    # Verify cleanup
    verify_cleanup
    
    echo
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}    ELK Stack Uninstall Completed!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo
    echo -e "${BLUE}Summary:${NC}"
    echo "✓ All ELK Stack components removed"
    echo "✓ Namespaces deleted"
    echo "✓ Persistent volumes cleaned up"
    echo "✓ Operators uninstalled"
    echo "✓ Custom Resource Definitions removed"
    echo
    echo -e "${YELLOW}Note: Some resources may take a few minutes to fully terminate.${NC}"
    echo -e "${YELLOW}If you encounter any issues, you can manually clean up remaining resources.${NC}"
    echo
    echo -e "${BLUE}To reinstall the ELK Stack:${NC}"
    echo "- For full setup: ./setup.sh"
    echo "- For lightweight setup: ./setup-lightweight.sh"
    echo "- For local cluster: ./setup-local-cluster.sh"
}

# Run main function
main "$@"
