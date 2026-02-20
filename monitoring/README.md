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

## Node Scheduling (Taints/Tolerations)

When deploying to nodes with taints, you need to configure tolerations for all components. This chart includes multiple subcharts (Prometheus Operator, Loki, Grafana Operator), each requiring their own tolerations configuration.

### Recommended: Use the Values Template File

The simplest approach is to copy and modify the included template file:

```bash
# Copy the template
cp monitoring/values-taint-template.yaml my-values.yaml

# Edit my-values.yaml - change the scheduling section:
#   scheduling:
#     tolerations:
#       - key: "your-taint-key"
#         operator: "Equal"
#         value: "your-taint-value"
#         effect: "NoSchedule"

# Install with your values
helm install monitoring ./monitoring -f my-values.yaml
```

The template uses YAML anchors to set tolerations once and apply them to all components automatically.

### Alternative: Set Values Individually

If you prefer to set values individually via `--set`, you need to configure each component:

```bash
helm install monitoring ./monitoring \
  --set 'global.tolerations[0].key=dedicated' \
  --set 'global.tolerations[0].operator=Equal' \
  --set 'global.tolerations[0].value=rocketchat' \
  --set 'global.tolerations[0].effect=NoSchedule' \
  --set 'operator.prometheusOperator.tolerations[0].key=dedicated' \
  --set 'operator.prometheusOperator.tolerations[0].operator=Equal' \
  --set 'operator.prometheusOperator.tolerations[0].value=rocketchat' \
  --set 'operator.prometheusOperator.tolerations[0].effect=NoSchedule' \
  --set 'operator.prometheusOperator.admissionWebhooks.patch.tolerations[0].key=dedicated' \
  --set 'operator.prometheusOperator.admissionWebhooks.patch.tolerations[0].operator=Equal' \
  --set 'operator.prometheusOperator.admissionWebhooks.patch.tolerations[0].value=rocketchat' \
  --set 'operator.prometheusOperator.admissionWebhooks.patch.tolerations[0].effect=NoSchedule' \
  --set 'operator.prometheus.prometheusSpec.tolerations[0].key=dedicated' \
  --set 'operator.prometheus.prometheusSpec.tolerations[0].operator=Equal' \
  --set 'operator.prometheus.prometheusSpec.tolerations[0].value=rocketchat' \
  --set 'operator.prometheus.prometheusSpec.tolerations[0].effect=NoSchedule' \
  --set 'operator.kube-state-metrics.tolerations[0].key=dedicated' \
  --set 'operator.kube-state-metrics.tolerations[0].operator=Equal' \
  --set 'operator.kube-state-metrics.tolerations[0].value=rocketchat' \
  --set 'operator.kube-state-metrics.tolerations[0].effect=NoSchedule' \
  --set 'operator.prometheus-node-exporter.tolerations[0].key=dedicated' \
  --set 'operator.prometheus-node-exporter.tolerations[0].operator=Equal' \
  --set 'operator.prometheus-node-exporter.tolerations[0].value=rocketchat' \
  --set 'operator.prometheus-node-exporter.tolerations[0].effect=NoSchedule' \
  --set 'grafana.tolerations[0].key=dedicated' \
  --set 'grafana.tolerations[0].operator=Equal' \
  --set 'grafana.tolerations[0].value=rocketchat' \
  --set 'grafana.tolerations[0].effect=NoSchedule' \
  --set 'loki.singleBinary.tolerations[0].key=dedicated' \
  --set 'loki.singleBinary.tolerations[0].operator=Equal' \
  --set 'loki.singleBinary.tolerations[0].value=rocketchat' \
  --set 'loki.singleBinary.tolerations[0].effect=NoSchedule' \
  --set 'loki.gateway.tolerations[0].key=dedicated' \
  --set 'loki.gateway.tolerations[0].operator=Equal' \
  --set 'loki.gateway.tolerations[0].value=rocketchat' \
  --set 'loki.gateway.tolerations[0].effect=NoSchedule'
```

> **Note:** The template file approach is much simpler. Use `--set` only when you cannot use a values file.

### Node Selector

For simple node selection without taints, you can use nodeSelector:

```yaml
# In your values file
global:
  nodeSelector:
    disktype: ssd
```

Or via command line:
```bash
helm install monitoring ./monitoring --set global.nodeSelector.disktype=ssd
```

## Customization

You can use all options available from the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart under the top-level `operator` key.


