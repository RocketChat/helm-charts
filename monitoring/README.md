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
  enabled: false
  ingressClassName: "traefik"
  tls: false
  Prometheus:
    enabled: true
    host: ""
    path: ""
  grafana:
    enabled: true
    host: ""
    path: ""
operator:
  Prometheus:
    PrometheusSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: <YOUR STORAGE CLASS> # Get available classes with: kubectl get storageclasses.storage.k8s.io
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

## Customization

You can use all options available from the [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) Helm chart under the top-level `operator` key.


