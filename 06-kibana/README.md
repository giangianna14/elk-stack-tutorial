# Kibana Visualization & Analytics

## Overview
Kibana adalah frontend visualization dan analytics platform untuk Elasticsearch. Dalam konteks e-commerce enterprise, Kibana menyediakan real-time insights untuk business intelligence, operational monitoring, dan security analytics.

## Real Use Case: E-commerce Business Intelligence Dashboard

### Business Stakeholders:
1. **CEO/Management**: Executive dashboard dengan KPIs utama
2. **Operations Team**: Real-time monitoring dan alerting
3. **Security Team**: Security events dan threat detection
4. **Business Analysts**: Revenue analysis dan customer insights
5. **DevOps Team**: Infrastructure monitoring dan troubleshooting

## Dashboard Architecture

### 1. Executive Dashboard
**Target Audience**: C-level executives, business managers
**Update Frequency**: Real-time
**Key Metrics**:
- Total revenue (hourly, daily, monthly)
- Order conversion rates
- Customer acquisition cost (CAC)
- Customer lifetime value (CLV)
- Geographic revenue distribution
- Top-selling products/categories

### 2. Operations Dashboard
**Target Audience**: Operations team, site reliability engineers
**Update Frequency**: Real-time (30-second refresh)
**Key Metrics**:
- System health indicators
- API response times
- Error rates by service
- Infrastructure resource utilization
- Queue depths (Kafka, Elasticsearch)
- Active user sessions

### 3. Security Dashboard
**Target Audience**: Security operations center (SOC)
**Update Frequency**: Real-time (10-second refresh)
**Key Metrics**:
- Failed authentication attempts
- Suspicious IP addresses
- Payment fraud indicators
- Data access patterns
- Compliance violations
- Threat intelligence feeds

### 4. Business Analytics Dashboard
**Target Audience**: Business analysts, marketing team
**Update Frequency**: Hourly/Daily
**Key Metrics**:
- Customer segmentation analysis
- Product performance metrics
- Marketing campaign effectiveness
- User journey analysis
- A/B test results
- Seasonal trends

## Advanced Visualization Examples

### 1. Real-time Revenue Tracking
```json
{
  "title": "Revenue by Hour",
  "type": "line",
  "params": {
    "grid": {"categoryLines": false, "style": {"color": "#eee"}},
    "categoryAxes": [{
      "id": "CategoryAxis-1",
      "type": "category",
      "position": "bottom",
      "show": true,
      "style": {},
      "scale": {"type": "linear"},
      "labels": {"show": true, "truncate": 100},
      "title": {}
    }],
    "valueAxes": [{
      "id": "ValueAxis-1",
      "name": "LeftAxis-1",
      "type": "value",
      "position": "left",
      "show": true,
      "style": {},
      "scale": {"type": "linear", "mode": "normal"},
      "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
      "title": {"text": "Revenue ($)"}
    }],
    "seriesParams": [{
      "show": true,
      "type": "line",
      "mode": "normal",
      "data": {"label": "Revenue", "id": "1"},
      "valueAxis": "ValueAxis-1",
      "drawLinesBetweenPoints": true,
      "showCircles": true
    }],
    "addTooltip": true,
    "addLegend": true,
    "legendPosition": "right",
    "times": [],
    "addTimeMarker": false
  }
}
```

### 2. Geographic Revenue Heatmap
```json
{
  "title": "Revenue by Geographic Region",
  "type": "region_map",
  "params": {
    "addTooltip": true,
    "legendPosition": "bottomright",
    "mapType": "Scaled Circle Markers",
    "isDisplayWarning": true,
    "wms": {
      "enabled": false,
      "options": {
        "format": "image/png",
        "transparent": true
      }
    },
    "mapZoom": 2,
    "mapCenter": [0, 0],
    "showAllShapes": true
  }
}
```

### 3. Error Rate Monitoring
```json
{
  "title": "Error Rate by Service",
  "type": "histogram",
  "params": {
    "grid": {"categoryLines": false, "style": {"color": "#eee"}},
    "categoryAxes": [{
      "id": "CategoryAxis-1",
      "type": "category",
      "position": "bottom",
      "show": true,
      "style": {},
      "scale": {"type": "linear"},
      "labels": {"show": true, "truncate": 100},
      "title": {}
    }],
    "valueAxes": [{
      "id": "ValueAxis-1",
      "name": "LeftAxis-1",
      "type": "value",
      "position": "left",
      "show": true,
      "style": {},
      "scale": {"type": "linear", "mode": "normal"},
      "labels": {"show": true, "rotate": 0, "filter": false, "truncate": 100},
      "title": {"text": "Error Rate (%)"}
    }],
    "seriesParams": [{
      "show": true,
      "type": "histogram",
      "mode": "stacked",
      "data": {"label": "Error Rate", "id": "1"},
      "valueAxis": "ValueAxis-1",
      "drawLinesBetweenPoints": true,
      "showCircles": true
    }],
    "addTooltip": true,
    "addLegend": true,
    "legendPosition": "right",
    "times": [],
    "addTimeMarker": false,
    "thresholdLine": {
      "show": true,
      "value": 5,
      "width": 2,
      "style": "full",
      "color": "#E7664C"
    }
  }
}
```

## Advanced Analytics Features

### 1. Machine Learning Anomaly Detection
```json
{
  "job_id": "revenue_anomaly_detection",
  "description": "Detect anomalies in hourly revenue",
  "analysis_config": {
    "bucket_span": "1h",
    "detectors": [{
      "detector_description": "sum(revenue)",
      "function": "sum",
      "field_name": "transaction.amount",
      "by_field_name": "service.name"
    }],
    "influencers": ["service.name", "user.segment"]
  },
  "data_description": {
    "time_field": "@timestamp",
    "time_format": "epoch_ms"
  },
  "results_index_name": "revenue-anomalies",
  "model_plot_config": {
    "enabled": true,
    "terms": "service.name"
  }
}
```

### 2. Canvas for Executive Presentations
```json
{
  "name": "Executive Summary",
  "description": "High-level business metrics for executive team",
  "workpad": {
    "id": "executive-summary-001",
    "name": "Q2 2025 Performance",
    "elements": [
      {
        "id": "revenue-metric",
        "type": "metric",
        "expression": "essql query=\"SELECT SUM(transaction.amount) as revenue FROM logs-production-business-* WHERE @timestamp >= NOW() - INTERVAL 1 DAY\" | math \"revenue\" | metric \"Total Revenue (24h)\" metricFont={font size=48 family=\"Open Sans\" color=\"#1f2937\" align=center lHeight=48}",
        "position": {"top": 50, "left": 50, "width": 300, "height": 150}
      },
      {
        "id": "orders-metric",
        "type": "metric", 
        "expression": "essql query=\"SELECT COUNT(*) as orders FROM logs-production-business-* WHERE event.type='order_created' AND @timestamp >= NOW() - INTERVAL 1 DAY\" | math \"orders\" | metric \"Orders (24h)\" metricFont={font size=36 family=\"Open Sans\" color=\"#059669\" align=center}",
        "position": {"top": 50, "left": 400, "width": 250, "height": 150}
      }
    ]
  }
}
```

### 3. Security SIEM Dashboard
```json
{
  "title": "Security Events Timeline",
  "type": "timeline",
  "params": {
    "expression": ".es(index=\"logs-production-security-*\") | .props(label=\"Security Events\") | .color(#d32f2f)",
    "interval": "auto"
  }
}
```

## Alerting & Monitoring

### 1. Revenue Drop Alert
```json
{
  "name": "Revenue Drop Alert",
  "schedule": {
    "interval": {
      "period": 5,
      "unit": "m"
    }
  },
  "input": {
    "search": {
      "request": {
        "search_type": "query_then_fetch",
        "indices": ["logs-production-business-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {"term": {"event.type": "transaction"}},
                {"range": {"@timestamp": {"gte": "now-1h"}}}
              ]
            }
          },
          "aggs": {
            "revenue": {"sum": {"field": "transaction.amount"}}
          }
        }
      }
    }
  },
  "condition": {
    "compare": {
      "ctx.payload.aggregations.revenue.value": {
        "lt": 10000
      }
    }
  },
  "actions": {
    "send_email": {
      "email": {
        "to": ["ops-team@company.com", "ceo@company.com"],
        "subject": "URGENT: Revenue drop detected",
        "body": "Hourly revenue dropped below $10,000. Current: ${{ctx.payload.aggregations.revenue.value}}"
      }
    },
    "slack_notification": {
      "slack": {
        "message": {
          "to": ["#alerts"],
          "text": "🚨 REVENUE ALERT: Hourly revenue below threshold",
          "attachments": [{
            "color": "danger",
            "title": "Revenue Drop Detected",
            "text": "Current hourly revenue: ${{ctx.payload.aggregations.revenue.value}}"
          }]
        }
      }
    }
  }
}
```

### 2. High Error Rate Alert
```json
{
  "name": "High Error Rate Alert",
  "schedule": {"interval": {"period": 2, "unit": "m"}},
  "input": {
    "search": {
      "request": {
        "indices": ["logs-production-applications-*"],
        "body": {
          "query": {
            "bool": {
              "must": [
                {"range": {"@timestamp": {"gte": "now-10m"}}}
              ]
            }
          },
          "aggs": {
            "by_service": {
              "terms": {"field": "service.name"},
              "aggs": {
                "total": {"value_count": {"field": "@timestamp"}},
                "errors": {
                  "filter": {"term": {"event.outcome": "failure"}},
                  "aggs": {"count": {"value_count": {"field": "@timestamp"}}}
                },
                "error_rate": {
                  "bucket_script": {
                    "buckets_path": {"errors": "errors>count", "total": "total"},
                    "script": "params.errors / params.total * 100"
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  "condition": {
    "script": {
      "source": "ctx.payload.aggregations.by_service.buckets.stream().anyMatch(service -> service.error_rate.value > 5)"
    }
  }
}
```

## Performance Optimization

### 1. Index Pattern Optimization
- Use time-based index patterns
- Limit field mapping explosions
- Optimize refresh intervals
- Use index aliases for seamless rotation

### 2. Query Performance
- Use filters instead of queries when possible
- Implement proper caching strategies
- Optimize aggregation queries
- Use runtime fields for ad-hoc analysis

### 3. Dashboard Loading
- Implement dashboard lazy loading
- Use saved searches for complex queries
- Optimize visualization refresh intervals
- Cache frequently accessed data

## User Experience Features

### 1. Role-based Dashboards
```yaml
# Executive Role
executive:
  allowed_indices: ["logs-production-business-*"]
  default_dashboard: "executive-summary"
  features: ["canvas", "reporting"]

# Operations Role  
operations:
  allowed_indices: ["logs-production-*", "metrics-*"]
  default_dashboard: "operations-overview"
  features: ["alerting", "watcher", "ml"]

# Security Role
security:
  allowed_indices: ["logs-production-security-*"]
  default_dashboard: "security-overview"
  features: ["siem", "endpoint", "alerting"]
```

### 2. Custom Branding
- Company logo and colors
- Custom CSS themes
- Branded login pages
- White-label reporting

## Business Value Metrics

### ROI Measurements:
1. **Reduced MTTR**: From 4 hours to 15 minutes
2. **Proactive Issue Detection**: 80% of issues caught before customer impact
3. **Business Intelligence**: 25% increase in data-driven decisions
4. **Compliance Efficiency**: 90% reduction in audit preparation time
5. **Operational Efficiency**: 40% reduction in manual monitoring tasks

### Cost Savings:
- **Reduced Downtime**: $500K saved annually
- **Improved Customer Experience**: 15% increase in customer satisfaction
- **Operational Efficiency**: 30% reduction in ops team overhead
- **Faster Development**: 50% faster debugging and troubleshooting

## Next Steps:
- [Dashboard Templates](./dashboards/)
- [Alert Configuration](./alerting/)
- [Custom Visualizations](./custom-viz/)
- [Reporting Automation](./reporting/)
