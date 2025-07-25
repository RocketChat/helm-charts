# Monitoring

This deploys helm chart deploys:
- Prometheus Operator
- Prometheus
- Prometheus Exporters
- Grafana
- Grafana dashboards

The basic configuration needed for this chart to work is as follow:

```yaml
ingress:
  enabled: false
  ingressClassName: "traefik"
  tls: false
  prometheus:
    enabled: true
    host: ""
    path: ""
  grafana:
    enabled: true
    host: ""
    path: ""
operator:
  prometheus:
    prometheusSpec:
      retention: 15d
      retentionSize: 30GB
      volumeClaimTemplate:
        spec:
          storageClassName: default
          resources:
            requests:
              storage: 31GB # Slightly higher than retentionSize
```

## Options

It is possible to use all the options available from [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) under the top level `operator` key.


