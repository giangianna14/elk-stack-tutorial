# Uninstall Guide - ELK Stack Tutorial

## Overview
Script `uninstall.sh` akan membersihkan semua komponen ELK Stack yang telah diinstall, termasuk data, konfigurasi, dan sumber daya terkait.

## ⚠️ **PERINGATAN PENTING**

**Script ini akan menghapus SEMUA data dan konfigurasi ELK Stack secara permanen!**
- ❌ Semua log data di Elasticsearch
- ❌ Semua dashboard dan visualisasi Kibana  
- ❌ Semua topic dan message Kafka
- ❌ Semua persistent volumes
- ❌ Semua aplikasi sample
- ❌ Operators dan Custom Resource Definitions

## 🚀 Quick Uninstall

```bash
# Jalankan script uninstall
./uninstall.sh

# Script akan meminta konfirmasi
# Ketik 'yes' untuk melanjutkan
```

## 📋 Apa yang Akan Dihapus

### 📦 **Namespaces**
- `kafka` - Kafka cluster dan komponen
- `elastic-system` - Elasticsearch, Kibana, Logstash, Filebeat
- `ecommerce-prod` - Sample e-commerce applications
- `demo-apps` - Demo applications (lightweight setup)

### 🔧 **Operators**
- **Strimzi Kafka Operator** - Mengelola Kafka clusters
- **Elastic Cloud on Kubernetes (ECK)** - Mengelola Elasticsearch & Kibana

### 💾 **Data & Storage**
- **Elasticsearch indices** - Semua log data dan metrics
- **Kafka topics** - Semua stream data
- **Persistent Volumes** - Storage untuk Elasticsearch dan Kafka
- **ConfigMaps & Secrets** - Konfigurasi dan credentials

### 🔐 **RBAC Resources**
- **Service Accounts** - Identitas untuk services
- **Roles & RoleBindings** - Permission definitions
- **ClusterRoles & ClusterRoleBindings** - Cluster-wide permissions
- **Custom Resource Definitions** - Kafka dan Elastic CRDs

## 🔄 Proses Uninstall Step-by-Step

### 1. **Environment Detection**
```bash
[INFO] Detected OpenShift environment
# atau
[INFO] Detected Kubernetes environment
```

### 2. **Confirmation Warning**
```
⚠️  WARNING: This will completely remove all ELK stack components! ⚠️

The following will be deleted:
📦 Namespaces:
   - kafka (Kafka cluster)
   - elastic-system (Elasticsearch, Kibana, Logstash, Filebeat)
   - ecommerce-prod (Sample applications)
   - demo-apps (Demo applications)

Are you sure you want to continue? (type 'yes' to confirm):
```

### 3. **Component Removal (dalam urutan)**
```bash
[INFO] Removing sample applications...
[INFO] Removing Filebeat...
[INFO] Removing Logstash...
[INFO] Removing Kibana...
[INFO] Removing Elasticsearch...
[INFO] Removing Kafka cluster...
[INFO] Removing persistent volumes...
[INFO] Removing namespaces...
[INFO] Removing operators...
[INFO] Removing Custom Resource Definitions...
```

### 4. **Local Cluster Cleanup (Opsional)**
```bash
[INFO] Checking for local cluster cleanup...
OpenShift Local (CRC) is running. Do you want to stop it? (y/N):
Minikube is running. Do you want to stop it? (y/N):
Found Kind clusters: elk-tutorial. Do you want to delete Kind clusters? (y/N):
```

### 5. **Verification**
```bash
[INFO] Verifying cleanup...
[INFO] Cleanup verification completed ✓
```

## 🎛️ Advanced Options

### Manual Cleanup Commands

Jika script gagal atau Anda ingin cleanup manual:

#### **Untuk OpenShift:**
```bash
# Remove namespaces
oc delete namespace kafka elastic-system ecommerce-prod demo-apps --grace-period=0 --force

# Remove operators
oc delete subscription strimzi-kafka-operator -n openshift-operators
oc delete subscription elastic-cloud-eck -n openshift-operators

# Remove CRDs
oc delete crd kafkas.kafka.strimzi.io
oc delete crd elasticsearches.elasticsearch.k8s.elastic.co
oc delete crd kibanas.kibana.k8s.elastic.co

# Remove persistent volumes
oc delete pv --all --selector='app in (elasticsearch,kafka)'
```

#### **Untuk Kubernetes:**
```bash
# Remove namespaces
kubectl delete namespace kafka elastic-system ecommerce-prod demo-apps --grace-period=0 --force

# Remove operators (jika diinstall via manifests)
kubectl delete -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml
kubectl delete -f https://strimzi.io/install/latest?namespace=kafka

# Remove CRDs
kubectl delete crd kafkas.kafka.strimzi.io
kubectl delete crd elasticsearches.elasticsearch.k8s.elastic.co

# Remove persistent volumes
kubectl delete pv --all --selector='app in (elasticsearch,kafka)'
```

### Force Cleanup Stuck Resources

Jika ada resource yang stuck di "Terminating":

```bash
# Force delete stuck namespaces
kubectl patch namespace kafka -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl patch namespace elastic-system -p '{"metadata":{"finalizers":null}}' --type=merge

# Force delete stuck pods
kubectl delete pods --all -n kafka --grace-period=0 --force
kubectl delete pods --all -n elastic-system --grace-period=0 --force

# Force delete stuck PVCs
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}' --type=merge
```

## 🔍 Troubleshooting

### Common Issues

#### **1. Namespaces Stuck in "Terminating"**
```bash
# Check what's blocking deletion
kubectl get namespace kafka -o yaml
kubectl describe namespace kafka

# Look for finalizers and remove them
kubectl patch namespace kafka -p '{"metadata":{"finalizers":[]}}' --type=merge
```

#### **2. PVs Not Deleted**
```bash
# Check PV status
kubectl get pv

# Force delete specific PV
kubectl patch pv <pv-name> -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl delete pv <pv-name> --grace-period=0 --force
```

#### **3. CRDs Still Present**
```bash
# List remaining CRDs
kubectl get crd | grep -E "(kafka|elastic)"

# Force delete specific CRD
kubectl delete crd <crd-name> --grace-period=0 --force
```

#### **4. Local Cluster Issues**
```bash
# For OpenShift Local (CRC)
crc stop
crc delete

# For Minikube
minikube stop
minikube delete

# For Kind
kind delete cluster --name elk-tutorial
```

## ✅ Verification Checklist

Setelah uninstall, verifikasi bahwa semua sudah bersih:

```bash
# Check namespaces
kubectl get namespaces | grep -E "(kafka|elastic|ecommerce|demo)"

# Check CRDs
kubectl get crd | grep -E "(kafka|elastic)"

# Check persistent volumes
kubectl get pv

# Check operators (OpenShift)
oc get subscription -n openshift-operators | grep -E "(strimzi|elastic)"

# Check cluster status
kubectl cluster-info
```

## 🔄 Reinstall After Cleanup

Setelah cleanup berhasil, Anda bisa reinstall:

```bash
# For full setup
./setup.sh

# For lightweight setup  
./setup-lightweight.sh

# For local cluster setup
./setup-local-cluster.sh
```

## 📞 Support

Jika mengalami masalah:

1. **Check logs**: `kubectl logs <pod-name> -n <namespace>`
2. **Check events**: `kubectl get events --sort-by=.metadata.creationTimestamp`
3. **Manual cleanup**: Gunakan command manual di atas
4. **Reset cluster**: Restart local cluster jika diperlukan

---

**⚠️ Reminder: Backup data penting sebelum menjalankan uninstall!**

## ✅ Script Validation

Script `uninstall.sh` telah divalidasi dan ditest dengan hasil:

### ✅ Test Results
- **Script Syntax**: ✓ Valid bash syntax
- **Permissions**: ✓ Executable (755)
- **Environment Detection**: ✓ OpenShift dan Kubernetes
- **Component Removal**: ✓ Semua komponen ELK Stack
- **Local Cluster Cleanup**: ✓ CRC, Minikube, Kind
- **Verification**: ✓ Cleanup validation

### 🧪 Test Command
```bash
# Test script syntax dan fungsi
./test-scripts.sh

# Test environment detection (tanpa eksekusi)
bash -n uninstall.sh && echo "Script valid ✓"
```
