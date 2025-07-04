# Elasticsearch Configuration for ELK Stack

## Overview
Elasticsearch adalah distributed search dan analytics engine yang menyimpan, mengindex, dan memungkinkan pencarian real-time terhadap log data dari seluruh infrastructure.

## Real Use Case: E-commerce Search & Analytics Platform

### Business Requirements:
1. **Multi-Tenant Architecture**: Isolasi data per customer/environment
2. **High Performance**: Sub-second search responses
3. **Scalability**: Handle 10TB+ daily log ingestion
4. **Data Lifecycle**: Hot/warm/cold storage optimization
5. **Security**: Role-based access control
6. **Compliance**: Data retention policies
7. **Business Intelligence**: Real-time analytics dashboard

## Cluster Architecture

### Production Cluster Design:
```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼───┐        ┌───▼───┐        ┌───▼───┐
│Master │        │Master │        │Master │
│Node 1 │        │Node 2 │        │Node 3 │
└───────┘        └───────┘        └───────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼───┐        ┌───▼───┐        ┌───▼───┐
│ Data  │        │ Data  │        │ Data  │
│Node 1 │        │Node 2 │        │Node 3 │
│ (Hot) │        │ (Hot) │        │ (Hot) │
└───────┘        └───────┘        └───────┘
    │                 │                 │
┌───▼───┐        ┌───▼───┐        ┌───▼───┐
│ Data  │        │ Data  │        │ Data  │
│Node 4 │        │Node 5 │        │Node 6 │
│(Warm) │        │(Warm) │        │(Warm) │
└───────┘        └───────┘        └───────┘
    │                 │                 │
┌───▼───┐        ┌───▼───┐        ┌───▼───┐
│ Data  │        │ Data  │        │ Data  │
│Node 7 │        │Node 8 │        │Node 9 │
│(Cold) │        │(Cold) │        │(Cold) │
└───────┘        └───────┘        └───────┘
```

## Index Strategy & Data Modeling

### Time-based Index Pattern:
```
logs-production-applications-2025.06.28
logs-production-security-2025.06.28
logs-production-business-2025.06.28
metrics-infrastructure-2025.06.28
```

### Index Template Example:
```json
{
  "index_patterns": ["logs-production-*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy",
      "index.codec": "best_compression",
      "index.mapping.total_fields.limit": 2000,
      "index.refresh_interval": "30s"
    },
    "mappings": {
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "service": {
          "properties": {
            "name": {"type": "keyword"},
            "version": {"type": "keyword"},
            "environment": {"type": "keyword"}
          }
        },
        "event": {
          "properties": {
            "category": {"type": "keyword"},
            "type": {"type": "keyword"},
            "outcome": {"type": "keyword"}
          }
        },
        "message": {
          "type": "text",
          "analyzer": "standard"
        },
        "user": {
          "properties": {
            "id": {"type": "keyword"},
            "email": {"type": "keyword"},
            "segment": {"type": "keyword"}
          }
        }
      }
    }
  }
}
```

## Data Lifecycle Management (ILM)

### Lifecycle Policy:
```json
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "10GB",
            "max_age": "1d",
            "max_docs": 10000000
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0,
            "include": {
              "data_tier": "warm"
            }
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "number_of_replicas": 0,
            "include": {
              "data_tier": "cold"
            }
          },
          "set_priority": {
            "priority": 0
          }
        }
      },
      "delete": {
        "min_age": "365d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

## Performance Optimization

### Hardware Specifications:

#### Hot Nodes (Real-time data):
- **CPU**: 16 cores (3.2GHz+)
- **RAM**: 64GB (32GB heap)
- **Storage**: NVMe SSD, 2TB
- **Network**: 10Gbps

#### Warm Nodes (Recent data):
- **CPU**: 8 cores (2.4GHz)
- **RAM**: 32GB (16GB heap)
- **Storage**: SSD, 4TB
- **Network**: 1Gbps

#### Cold Nodes (Archive data):
- **CPU**: 4 cores (2.0GHz)
- **RAM**: 16GB (8GB heap)
- **Storage**: HDD, 8TB
- **Network**: 1Gbps

### JVM Tuning:
```yaml
ES_JAVA_OPTS: >
  -Xms32g
  -Xmx32g
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:+UnlockExperimentalVMOptions
  -XX:+UseCGroupMemoryLimitForHeap
  -XX:+DisableExplicitGC
  -Djava.io.tmpdir=/var/tmp
```

## Security Implementation

### Role-Based Access Control:
```yaml
# Production Read-Only Role
production_readonly:
  cluster: ["monitor"]
  indices:
    - names: ["logs-production-*"]
      privileges: ["read", "view_index_metadata"]
      
# Security Team Role
security_team:
  cluster: ["monitor", "manage_index_templates"]
  indices:
    - names: ["logs-production-security-*", "logs-production-applications-*"]
      privileges: ["read", "write", "create_index", "manage"]
      
# DevOps Team Role
devops_team:
  cluster: ["monitor", "manage_ilm"]
  indices:
    - names: ["logs-*", "metrics-*"]
      privileges: ["all"]
```

### Authentication Methods:
1. **LDAP Integration**: Corporate directory
2. **SAML SSO**: Single sign-on
3. **API Keys**: Service-to-service authentication
4. **PKI**: Certificate-based authentication

## Business Intelligence Queries

### 1. Real-time Revenue Tracking:
```json
{
  "query": {
    "bool": {
      "must": [
        {"term": {"event.category": "business"}},
        {"term": {"event.type": "transaction"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  },
  "aggs": {
    "total_revenue": {
      "sum": {"field": "transaction.amount"}
    },
    "revenue_by_minute": {
      "date_histogram": {
        "field": "@timestamp",
        "fixed_interval": "1m"
      },
      "aggs": {
        "revenue": {"sum": {"field": "transaction.amount"}}
      }
    }
  }
}
```

### 2. Error Rate Analysis:
```json
{
  "query": {
    "bool": {
      "must": [
        {"term": {"service.environment": "production"}},
        {"range": {"@timestamp": {"gte": "now-24h"}}}
      ]
    }
  },
  "aggs": {
    "error_rate_by_service": {
      "terms": {"field": "service.name"},
      "aggs": {
        "total_requests": {"value_count": {"field": "@timestamp"}},
        "error_requests": {
          "filter": {"term": {"event.outcome": "failure"}},
          "aggs": {
            "count": {"value_count": {"field": "@timestamp"}}
          }
        },
        "error_rate": {
          "bucket_script": {
            "buckets_path": {
              "errors": "error_requests>count",
              "total": "total_requests"
            },
            "script": "params.errors / params.total * 100"
          }
        }
      }
    }
  }
}
```

### 3. User Behavior Analysis:
```json
{
  "query": {
    "bool": {
      "must": [
        {"term": {"event.category": "user_activity"}},
        {"range": {"@timestamp": {"gte": "now-7d"}}}
      ]
    }
  },
  "aggs": {
    "user_journey": {
      "terms": {"field": "user.id"},
      "aggs": {
        "page_views": {
          "terms": {"field": "page.url"},
          "aggs": {
            "timeline": {
              "date_histogram": {
                "field": "@timestamp",
                "fixed_interval": "1h"
              }
            }
          }
        },
        "session_duration": {
          "max": {"field": "@timestamp"}
        }
      }
    }
  }
}
```

## Monitoring & Alerting

### Key Metrics:
1. **Cluster Health**: Green/Yellow/Red status
2. **Indexing Rate**: Documents per second
3. **Query Performance**: Average response time
4. **Storage Usage**: Disk utilization per node
5. **JVM Heap**: Memory usage patterns

### Critical Alerts:
- Cluster status != green
- Disk usage > 85%
- JVM heap > 75%
- Query latency > 1 second
- Index failures > 1%

## Disaster Recovery

### Backup Strategy:
```yaml
snapshot_repository:
  type: s3
  settings:
    bucket: elasticsearch-backups
    region: us-east-1
    base_path: production-cluster
    
snapshot_policy:
  schedule: "0 2 * * *"  # Daily at 2 AM
  name: "daily-snapshot-{now/d}"
  repository: production-repo
  config:
    indices: ["logs-*", "metrics-*"]
    include_global_state: false
  retention:
    expire_after: 30d
    min_count: 5
    max_count: 50
```

### Recovery Procedures:
1. **Point-in-time Recovery**: Restore specific indices
2. **Full Cluster Recovery**: Complete cluster restoration
3. **Cross-region Replication**: Real-time data replication

## Next Steps:
- [Cluster Setup](./cluster/)
- [Index Templates](./templates/)
- [Monitoring Dashboard](./monitoring/)
- [Performance Tuning](./performance/)
