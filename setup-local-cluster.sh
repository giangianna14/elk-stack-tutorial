#!/bin/bash

# ELK Stack Tutorial - Local Cluster Setup Script
# This script helps you set up a local OpenShift or Kubernetes cluster for the tutorial

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  ELK Stack Tutorial - Local Setup${NC}"
echo -e "${BLUE}=======================================${NC}"
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

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check RAM (minimum 8GB for OpenShift Local)
    total_mem=$(free -g | awk 'NR==2{print $2}')
    if [ $total_mem -lt 8 ]; then
        print_error "Insufficient RAM. Need at least 8GB for OpenShift Local, you have ${total_mem}GB"
        exit 1
    fi
    
    # Check CPU cores (minimum 4 cores)
    cpu_cores=$(nproc)
    if [ $cpu_cores -lt 4 ]; then
        print_error "Insufficient CPU cores. Need at least 4 cores, you have ${cpu_cores}"
        exit 1
    fi
    
    # Check disk space (minimum 30GB, recommended 35GB)
    free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $free_space -lt 25 ]; then
        print_error "Insufficient disk space. Need at least 25GB free, you have ${free_space}GB"
        exit 1
    elif [ $free_space -lt 35 ]; then
        print_warning "Limited disk space. You have ${free_space}GB free (recommended: 35GB+)"
        print_warning "Consider using Kind or Minikube for lighter resource usage"
        echo
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            echo "Exiting. Please free up more disk space or choose a lighter option."
            exit 1
        fi
    fi
    
    print_status "System requirements check passed ✓"
    echo -e "  RAM: ${total_mem}GB, CPU: ${cpu_cores} cores, Disk: ${free_space}GB free"
}

# Install OpenShift Local (CRC)
install_openshift_local() {
    print_status "Installing OpenShift Local..."
    
    # Check if CRC is already installed
    if command -v crc &> /dev/null; then
        print_status "OpenShift Local is already installed"
        return 0
    fi
    
    # Download CRC
    CRC_VERSION="2.32.0"
    CRC_URL="https://developers.redhat.com/content-gateway/file/pub/openshift-v4/clients/crc/${CRC_VERSION}/crc-linux-amd64.tar.xz"
    
    print_status "Downloading OpenShift Local v${CRC_VERSION}..."
    wget -q --show-progress $CRC_URL -O crc-linux-amd64.tar.xz
    
    # Extract and install
    tar -xf crc-linux-amd64.tar.xz
    sudo mv crc-linux-*-amd64/crc /usr/local/bin/
    
    # Clean up
    rm -rf crc-linux-amd64.tar.xz crc-linux-*-amd64/
    
    print_status "OpenShift Local installed successfully ✓"
}

# Setup and start OpenShift Local
setup_openshift_local() {
    print_status "Setting up OpenShift Local..."
    
    # Check if we have enough space for full setup
    if [ $free_space -lt 35 ]; then
        print_warning "Limited disk space (${free_space}GB). OpenShift Local may not work optimally."
        print_warning "Consider using Minikube or Kind instead."
        echo
        read -p "Continue with OpenShift Local anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            echo "Returning to main menu..."
            return 1
        fi
    fi
    
    # Setup CRC
    crc setup
    
    # Configure memory (adjust based on available space)
    memory_mb=10240
    disk_size=40
    if [ $free_space -lt 35 ]; then
        memory_mb=8192
        disk_size=30
        print_warning "Using reduced resources due to disk space constraints"
    fi
    
    crc config set memory $memory_mb
    crc config set cpus 4
    crc config set disk-size $disk_size
    
    print_status "Starting OpenShift Local (this may take 10-15 minutes)..."
    crc start
    
    # Get cluster info
    eval $(crc oc-env)
    
    print_status "OpenShift Local is ready! ✓"
    echo
    echo -e "${GREEN}Cluster Information:${NC}"
    crc console --credentials
    echo
    echo -e "${BLUE}To access your cluster:${NC}"
    echo "eval \$(crc oc-env)"
    echo "oc login -u kubeadmin -p \$(crc console --credentials | grep kubeadmin | cut -d' ' -f2)"
}

# Install Minikube as alternative
install_minikube() {
    print_status "Installing Minikube..."
    
    # Check if minikube is already installed
    if command -v minikube &> /dev/null; then
        print_status "Minikube is already installed"
        return 0
    fi
    
    # Download and install minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    print_status "Minikube installed successfully ✓"
}

# Setup Minikube with sufficient resources
setup_minikube() {
    print_status "Setting up Minikube..."
    
    # Adjust resources based on available space
    memory_mb=6144
    if [ $free_space -lt 30 ]; then
        memory_mb=4096
        print_warning "Using reduced memory (4GB) due to disk space constraints"
    fi
    
    # Start minikube with sufficient resources
    minikube start --driver=docker --memory=$memory_mb --cpus=3 --disk-size=25g
    
    # Enable required addons
    minikube addons enable ingress
    minikube addons enable storage-provisioner
    
    print_status "Minikube is ready! ✓"
    echo
    echo -e "${GREEN}Cluster Information:${NC}"
    kubectl cluster-info
    echo
    echo -e "${BLUE}To access your cluster:${NC}"
    echo "kubectl get nodes"
}

# Install Kind (Kubernetes in Docker)
install_kind() {
    print_status "Installing Kind..."
    
    # Check if kind is already installed
    if command -v kind &> /dev/null; then
        print_status "Kind is already installed"
        return 0
    fi
    
    # Install kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    
    print_status "Kind installed successfully ✓"
}

# Setup Kind cluster
setup_kind() {
    print_status "Setting up Kind cluster..."
    
    # Create kind cluster configuration
    cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
  - containerPort: 30001
    hostPort: 30001
  - containerPort: 30002
    hostPort: 30002
- role: worker
- role: worker
- role: worker
EOF
    
    # Create cluster
    kind create cluster --config kind-config.yaml --name elk-tutorial
    
    # Set kubectl context
    kubectl cluster-info --context kind-elk-tutorial
    
    print_status "Kind cluster is ready! ✓"
    echo
    echo -e "${GREEN}Cluster Information:${NC}"
    kubectl get nodes
    echo
    echo -e "${BLUE}To access your cluster:${NC}"
    echo "kubectl config use-context kind-elk-tutorial"
    
    # Clean up
    rm kind-config.yaml
}

# Main menu
show_menu() {
    echo -e "${BLUE}Choose your local development environment:${NC}"
    echo "1) OpenShift Local (CRC) - Full OpenShift experience (requires 35GB+)"
    echo "2) Minikube - Lightweight Kubernetes (requires 25GB+)"
    echo "3) Kind - Kubernetes in Docker (requires 20GB+)"
    echo "4) Check existing cluster"
    echo "5) Exit"
    echo
    echo -e "${YELLOW}Note: Your available disk space: ${free_space}GB${NC}"
    echo
    read -p "Enter your choice [1-5]: " choice
}

# Check existing cluster
check_existing_cluster() {
    print_status "Checking for existing clusters..."
    
    # Check for OpenShift Local
    if command -v crc &> /dev/null; then
        crc_status=$(crc status 2>/dev/null | grep "CRC VM" | awk '{print $3}' || echo "Unknown")
        echo -e "OpenShift Local: ${crc_status}"
        if [ "$crc_status" = "Running" ]; then
            echo -e "${GREEN}✓ OpenShift Local is running${NC}"
            echo "Run: eval \$(crc oc-env) && oc login -u kubeadmin"
        fi
    fi
    
    # Check for Minikube
    if command -v minikube &> /dev/null; then
        minikube_status=$(minikube status -f "{{.Host}}" 2>/dev/null || echo "Unknown")
        echo -e "Minikube: ${minikube_status}"
        if [ "$minikube_status" = "Running" ]; then
            echo -e "${GREEN}✓ Minikube is running${NC}"
            echo "Run: kubectl get nodes"
        fi
    fi
    
    # Check for Kind
    if command -v kind &> /dev/null; then
        kind_clusters=$(kind get clusters 2>/dev/null || echo "")
        if [ -n "$kind_clusters" ]; then
            echo -e "Kind clusters: ${kind_clusters}"
            echo -e "${GREEN}✓ Kind clusters available${NC}"
            echo "Run: kubectl config use-context kind-<cluster-name>"
        fi
    fi
    
    # Check for kubectl
    if command -v kubectl &> /dev/null; then
        if kubectl cluster-info &> /dev/null; then
            echo -e "${GREEN}✓ kubectl is connected to a cluster${NC}"
            kubectl get nodes
        else
            echo -e "${YELLOW}kubectl is installed but not connected to a cluster${NC}"
        fi
    fi
}

# Main execution
main() {
    check_requirements
    
    while true; do
        show_menu
        
        case $choice in
            1)
                install_openshift_local
                setup_openshift_local
                break
                ;;
            2)
                install_minikube
                setup_minikube
                break
                ;;
            3)
                install_kind
                setup_kind
                break
                ;;
            4)
                check_existing_cluster
                echo
                ;;
            5)
                echo "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-5."
                ;;
        esac
    done
    
    echo
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}  Local cluster setup completed!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Verify cluster access:"
    echo "   - For OpenShift: oc get nodes"
    echo "   - For Kubernetes: kubectl get nodes"
    echo
    echo "2. Run the ELK stack setup:"
    echo "   ./setup.sh"
    echo
    echo "3. Follow the tutorial in QUICK_START.md"
}

# Run main function
main "$@"
