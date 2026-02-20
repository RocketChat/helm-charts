# Monitoring Helm Chart

This Helm chart deploys a complete monitoring stack, including:
- Prometheus Operator
- Prometheus
- Prometheus Exporters
- Grafana
- Pre-configured Grafana dashboards

## Basic Configuration

Below is a minimal configuration example to get started:

```yaml
ingress:
  enabled: true
  ingressClassName: "traefik"
  tls: false
  Prometheus:
    enabled: false
    host: ""
    path: ""
  grafana:
    enabled: true
    host: "grafana.localhost"
    path: ""
operator:
  prometheus:
    prometheusSpec:
      storageSpec:
        volumeClaimTemplate:
          spec:
            storageClassName: <YOUR STORAGE CLASS> # Get available classes with: kubectl get storageclasses.storage.k8s.io
grafana:
  enabled: true
  deploy:
    storageClassName: <YOUR STORAGE CLASS> # Get available classes with: kubectl get storageclasses.
```

If instead of ingress you wan't to bind a NodePort, you can use as:

```yaml
grafana:
  nodePort: 3050
```

## Storage and Retention

To change the default retention settings, modify the values below. For more details, see the [Prometheus storage documentation](https://prometheus.io/docs/prometheus/latest/storage/).

**Disk space calculation:**
```
needed_disk_space = retention_time_seconds * ingested_samples_per_second * bytes_per_sample
```

**Typical usage:**  
With Rocket.Chat, MongoDB, and Kubernetes metrics scraped every 60 seconds, expect around **200–250 MB per day** for a single-node cluster (k3s or kind).  
- Add ~50 MB/day for each additional Kubernetes node (due to extra kubelet and node-exporter metrics).
- Add ~15 MB/day for each additional MongoDB replica.

> **Note:**  
> These estimates do **not** account for other workloads or applications running in your cluster.  
> If you are running additional services or exporting more metrics, you should increase the storage and retention values accordingly.

> The storage request should be at least 15% higher than the *retentionSize*.  
> If the disk becomes full, Prometheus may be unable to read the TSDB during a restart.  
> Using a larger storage request minimizes the chance of this issue occurring.

**Recommended settings for single node cluster:**
- Scrape interval: 60s
- Retention: 15 days
- Minimum storage: 4 GB for Prometheus


Example configuration:
```yaml
operator:
  Prometheus:
    PrometheusSpec:
      retention: 15d
      retentionSize: 8GB
      volumeClaimTemplate:
        spec:
          storageClassName: <YOUR STORAGE CLASS> # Get available classes with: kubectl get storageclasses.storage.k8s.io
          resources:
            requests:
              storage: 10GB # Should be at least 15% heigher than retetion size
```

## Loki and Open Telemetry

### Loki - Log Aggregation

Loki is a log aggregation system designed to store and index logs from all pods in your Kubernetes cluster. It works in conjunction with Grafana to provide a centralized log viewing experience.

**Key Features:**
- Minimal storage overhead through label-based indexing
- Integration with Grafana for querying and visualization
- Automatic log retention based on configured policies

#### Storage and Retention Configuration

**Storage Size** (`loki.singleBinary.persistence.size`):
- Default: `50Gi`
- Defines the total disk space allocated for storing logs
- Calculation: Daily log volume × retention period = required storage
- Typical single-node cluster generates **100–200 MB of logs per day**

**Retention Period** (`loki.loki.limits_config.retention_period`):
- Default: `15d` (15 days)
- Older logs are automatically deleted by the compactor
- Shorter retention saves disk space; longer retention aids troubleshooting

> **Important:** If the disk becomes full, Loki will stop ingesting logs and require manual intervention to recover. Ensure your storage allocation is adequate for your expected log volume and desired retention period.
> 
> **Calculate required storage:**
> ```
> required_storage = daily_log_volume_MB × retention_days × 1.2 (20% buffer)
> ```

**To increase retention and storage:**

```yaml
loki:
  singleBinary:
    persistence:
      size: 100Gi  # Increase disk allocation
  
  loki:
    limits_config:
      retention_period: 30d  # Increase retention to 30 days
```

**Before increasing these values:**
1. Calculate your expected daily log volume across all pods
2. Ensure your Kubernetes cluster has sufficient disk space
3. Leave a 20% buffer above the calculated storage (e.g., if you need 80 GB, allocate 100 GB)
4. Monitor disk usage to prevent the disk from becoming full

### OpenTelemetry - Metrics and Tracing

OpenTelemetry is an open-source observability framework that collects metrics, logs, and traces from your applications and infrastructure. The OpenTelemetry Operator manages the deployment and configuration of collectors.

**Key Components:**
- **OpenTelemetry Collector**: Receives, processes, and exports telemetry data
- **ServiceMonitor Integration**: Automatically discovers and monitors services with metrics
- **Resource Attribute Indexing**: Labels metrics for efficient querying (service name, namespace, pod name, etc.)

**Current Configuration:**
- The operator is enabled and manages the collector lifecycle
- Collectors automatically index metrics using Kubernetes and OpenTelemetry resource attributes
- Metrics are scraped from services and exported to Prometheus

For advanced configuration options, refer to the [OpenTelemetry Operator documentation](https://opentelemetry.io/docs/kubernetes/operator/).

## Node Scheduling

You can control pod placement using `nodeSelector`, `tolerations`, and `affinity`. These can be configured globally (applied to all components) or per-component.

### Global Configuration

Set scheduling constraints for all monitoring components:

```yaml
global:
  nodeSelector:
    disktype: ssd
  tolerations:
    - key: "node-role"
      operator: "Exists"
      effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/zone
                operator: In
                values:
                  - us-east-1a
```

### Per-Component Configuration

Override global settings for specific components:

```yaml
grafana:
  nodeSelector:
    disktype: ssd
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "monitoring"
      effect: "NoSchedule"

opentelemetryCollector:
  nodeSelector:
    role: logging
  tolerations: []
```

### Using `--set` Flags

**Node Selector:**
```bash
# Global nodeSelector
helm install monitoring ./monitoring \
  --set global.nodeSelector.disktype=ssd

# Component-specific nodeSelector
helm install monitoring ./monitoring \
  --set grafana.nodeSelector.disktype=ssd \
  --set opentelemetryCollector.nodeSelector.role=logging
```

**Tolerations:**
```bash
# Global toleration
helm install monitoring ./monitoring \
  --set 'global.tolerations[0].key=node-role' \
  --set 'global.tolerations[0].operator=Exists' \
  --set 'global.tolerations[0].effect=NoSchedule'

# Component-specific toleration
helm install monitoring ./monitoring \
  --set 'grafana.tolerations[0].key=dedicated' \
  --set 'grafana.tolerations[0].operator=Equal' \
  --set 'grafana.tolerations[0].value=monitoring' \
  --set 'grafana.tolerations[0].effect=NoSchedule'
```

> **Note:** When using `--set` with array values like tolerations, you must quote the parameter to prevent shell interpretation of brackets.

Component-specific values take precedence over global values. If a component has its own `nodeSelector`, `tolerations`, or `affinity` defined, those will be used instead of the global settings.

## Customization

You can use all options available from the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart under the top-level `operator` key.


