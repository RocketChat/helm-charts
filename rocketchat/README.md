# Rocket.Chat

[Rocket.Chat](https://rocket.chat/) is free, unlimited and open source. Replace email, HipChat & Slack with the ultimate team chat software solution.

> **WARNING**: Upgrading to chart version 5.4.3 or higher might require extra steps to successfully update MongoDB and Rocket.Chat. See [Upgrading to 5.4.3](#to-543) for more details.

## Introduction

This chart bootstraps a [Rocket.Chat](https://rocket.chat/) Deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager. It provisions a fully featured Rocket.Chat installation.

In addition, this chart supports scaling of Rocket.Chat for increased server capacity and high availability (requires enterprise license).  For more information on Rocket.Chat and its capabilities, see its [documentation](https://rocket.chat/docs/).

## Prerequisites Details

The chart has an optional dependency on the [MongoDB](https://github.com/bitnami/charts/tree/master/bitnami/mongodb) chart.
By default, the MongoDB chart requires PV support on underlying infrastructure (may be disabled).

## Installing the Chart

To install the chart with the release name `rocketchat`:

```console
$ helm install rocketchat rocketchat/rocketchat --set mongodb.auth.passwords={rocketchatPassword},mongodb.auth.rootPassword=rocketchatRootPassword
```

If you got a registration token for [Rocket.Chat Cloud](https://cloud.rocket.chat), you can also include it: 
```console
$ helm install rocketchat rocketchat/rocketchat --set mongodb.auth.passwords={rocketchatPassword},mongodb.auth.rootPassword=rocketchatRootPassword,registrationToken=<paste the token here>
```

Usage of `Values.yaml` file is recommended over using command line arguments `--set`. You must set at least the database password and root password in the values file.

```yaml
mongodb:
  auth:
    passwords:
      - rocketchat
    rootPassword: rocketchatroot
```

Now use the following command to deploy
```shell
helm install rocketchat -f Values.yaml rocketchat/rocketchat
```

> Starting chart version 5.4.3, due to mongodb dependency, username, password and database entries must be arrays of the same length. Rocket.Chat will use the first entries of those arrays for its own use. `mongodb.auth.usernames` array defaults to `{rocketchat}` and `mongodb.auth.databases` array defaults to `{rocketchat}`

## Uninstalling the Chart

To uninstall/delete the `rocketchat` deployment:

```console
$ helm delete rocketchat
```

## Configuration

The following table lists the configurable parameters of the Rocket.Chat chart and their default values.

| Parameter                              | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Default                            |
|----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------|
| `image.repository`                     | Image repository                                                                                                                                                                                                                                                                                                                                                                                                                                               | `registry.rocket.chat/rocketchat/rocket.chat` |
| `image.tag`                            | Image tag                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `3.18.3`                           |
| `image.pullPolicy`                     | Image pull policy                                                                                                                                                                                                                                                                                                                                                                                                                                              | `IfNotPresent`                     |
| `host`                                 | Hostname for Rocket.Chat. Also used for ingress (if enabled)                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                               |
| `replicaCount`                         | Number of replicas to run                                                                                                                                                                                                                                                                                                                                                                                                                                      | `1`                                |
| `smtp.enabled`                         | Enable SMTP for sending mails                                                                                                                                                                                                                                                                                                                                                                                                                                  | `false`                            |
| `smtp.existingSecret`                  | Use existing secret for SMTP account                                                                                                                                                                                                                                                                                                                                                                                                                           | `""`                               |
| `smtp.username`                        | Username of the SMTP account                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                               |
| `smtp.password`                        | Password of the SMTP account                                                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                               |
| `smtp.host`                            | Hostname of the SMTP server                                                                                                                                                                                                                                                                                                                                                                                                                                    | `""`                               |
| `smtp.port`                            | Port of the SMTP server                                                                                                                                                                                                                                                                                                                                                                                                                                        | `587`                              |
| `extraEnv`                             | Extra environment variables for Rocket.Chat. Used with `tpl` function, so this needs to be a string                                                                                                                                                                                                                                                                                                                                                            | `""`                               |
| `extraSecret`                             | An already existing secret to be used by chat deployment. It needs to be a string                                                                                                                                                                                                                                                                                                                                                            | `""`                               |
| `extraVolumes`                         | Extra volumes allowing inclusion of certificates or any sort of file that might be required (see bellow)                                                                                                                                                                                                                                                                                                                                                       | `[]`                               |
| `extraVolumeMounts`                    | Where the aforementioned extra volumes should be mounted inside the container                                                                                                                                                                                                                                                                                                                                                                                  | `[]`                               |
| `podAntiAffinity`                      | Pod anti-affinity can prevent the scheduler from placing RocketChat replicas on the same node. The default value "soft" means that the scheduler should *prefer* to not schedule two replica pods onto the same node but no guarantee is provided. The value "hard" means that the scheduler is *required* to not schedule two replica pods onto the same node. The value "" will disable pod anti-affinity so that no anti-affinity rules will be configured. | `""`                               |
| `podAntiAffinityTopologyKey`           | If anti-affinity is enabled sets the topologyKey to use for anti-affinity. This can be changed to, for example `failure-domain.beta.kubernetes.io/zone`                                                                                                                                                                                                                                                                                                        | `kubernetes.io/hostname`           |
| `affinity`                             | Assign custom affinity rules to the RocketChat instance https://kubernetes.io/docs/concepts/configuration/assign-pod-node/                                                                                                                                                                                                                                                                                                                                     | `{}`                               |
| `minAvailable`                         | Minimum number / percentage of pods that should remain scheduled                                                                                                                                                                                                                                                                                                                                                                                               | `1`                                |
| `existingMongodbSecret`                | An already existing secret containing MongoDB Connection URL                                                                                                                                                                                                                                                                                                                                                                                                   | `""`                               |
| `externalMongodbUrl`                   | MongoDB URL if using an externally provisioned MongoDB                                                                                                                                                                                                                                                                                                                                                                                                         | `""`                               |
| `mongodb.enabled`                      | Enable or disable MongoDB dependency. Refer to the [stable/mongodb docs](https://github.com/bitnami/charts/tree/master/bitnami/mongodb#configuration) for more information                                                                                                                                                                                                                                                                                     | `true`                             |
| `mongodb.serviceMonitor.enabled` | Enable mongodb service monitor or service with scrape annotation | `true` |
| `persistence.enabled`                  | Enable persistence using a PVC. This is not necessary if you're using the default [GridFS](https://rocket.chat/docs/administrator-guides/file-upload/) file storage                                                                                                                                                                                                                                                                          | `false`                            |
| `persistence.storageClass`             | Storage class of the PVC to use                                                                                                                                                                                                                                                                                                                                                                                                                                | `""`                               |
| `persistence.accessMode`               | Access mode of the PVC                                                                                                                                                                                                                                                                                                                                                                                                                                         | `ReadWriteOnce`                    |
| `persistence.size`                     | Size of the PVC                                                                                                                                                                                                                                                                                                                                                                                                                                                | `8Gi`                              |
| `persistence.existingClaim`            | An Existing PVC name for rocketchat volume                                                                                                                                                                                                                                                                                                                                                                                                                     | `""`                               |
| `resources`                            | Pod resource requests and limits                                                                                                                                                                                                                                                                                                                                                                                                                               | `{}`                               |
| `securityContext.enabled`              | Enable security context for the pod                                                                                                                                                                                                                                                                                                                                                                                                                            | `true`                             |
| `securityContext.runAsUser`            | User to run the pod as                                                                                                                                                                                                                                                                                                                                                                                                                                         | `999`                              |
| `securityContext.fsGroup`              | fs group to use for the pod                                                                                                                                                                                                                                                                                                                                                                                                                                    | `999`                              |
| `serviceAccount.create`                | Specifies whether a ServiceAccount should be created                                                                                                                                                                                                                                                                                                                                                                                                           | `true`                             |
| `serviceAccount.name`                  | Name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template                                                                                                                                                                                                                                                                                                                                              | `""`                               |
| `ingress.enabled`                      | If `true`, an ingress is created                                                                                                                                                                                                                                                                                                                                                                                                                               | `false`                            |
| `ingress.pathType`                     | Sets the value for pathType for the created Ingress resource                                                                                                                                                                                                                                                                                                                                                                                                   | `Prefix`                           |
| `ingress.annotations`                  | Annotations for the ingress                                                                                                                                                                                                                                                                                                                                                                                                                                    | `{}`                               |
| `ingress.path`                         | Path of the ingress                                                                                                                                                                                                                                                                                                                                                                                                                                            | `/`                                |
| `ingress.tls`                          | A list of [IngressTLS](https://kubernetes.io/docs/reference/kubernetes-api/service-resources/ingress-v1/#IngressSpec) items                                                                                                                                                                                                                                                                                                                                    | `[]`                               |
| `license`                              | Contents of the Enterprise License file, if applicable                                                                                                                                                                                                                                                                                                                                                                                                         | `""`                               |
| `prometheusScraping.enabled`           | Turn on and off /metrics endpoint for Prometheus scraping                                                                                                                                                                                                                                                                                                                                                                                                      | `false`                            |
| `prometheusScraping.port`              | Port to use for the metrics for Prometheus to scrap on                                                                                                                                                                                                                                                                                                                                                                                                         | `9458`                             |
| `prometheusScraping.msPort`           | Port to use for microservices metrics                                                                                                                                                                                                                                                                                                                                                                                                                          | `9458`                             |
| `podMonitor.enabled`                   | Create podMonitor resource(s) for scraping metrics using PrometheusOperator (prometheusScraping should be enabled)                                                                                                                                                                                                                                                                                                                                             | `false`                            |
| `podMonitor.interval`                  | The interval at which metrics should be scraped                                                                                                                                                                                                                                                                                                                                                                                                                | `30s`                              |
| `serviceMonitor.enabled`               | Create ServiceMonitor resource(s) for scraping metrics using PrometheusOperator (prometheusScraping should be enabled)                                                                                                                                                                                                                                                                                                                                         | `false`                            |
| `serviceMonitor.intervals`              | The intervals at which metrics should be scraped                                                                                                                                                                                                                                                                                                                                                                                                                | `[30s]`                              |
| `serviceMonitor.ports`                  | The port names at which container exposes Prometheus metrics                                                                                                                                                                                                                                                                                                                                                                                                    | `[metrics]`                          |
| `serviceMonitor.interval`              | deprecated, use `serviceMonitor.intervals` instead | `30s`                              |
| `serviceMonitor.port`                  | deprecated, use `serviceMonitor.ports` instead | `metrics`                          |
| `livenessProbe.enabled`                | Turn on and off liveness probe                                                                                                                                                                                                                                                                                                                                                                                                                                 | `true`                             |
| `livenessProbe.initialDelaySeconds`    | Delay before liveness probe is initiated                                                                                                                                                                                                                                                                                                                                                                                                                       | `60`                               |
| `livenessProbe.periodSeconds`          | How often to perform the probe                                                                                                                                                                                                                                                                                                                                                                                                                                 | `15`                               |
| `livenessProbe.timeoutSeconds`         | When the probe times out                                                                                                                                                                                                                                                                                                                                                                                                                                       | `5`                                |
| `livenessProbe.failureThreshold`       | Minimum consecutive failures for the probe                                                                                                                                                                                                                                                                                                                                                                                                                     | `3`                                |
| `livenessProbe.successThreshold`       | Minimum consecutive successes for the probe                                                                                                                                                                                                                                                                                                                                                                                                                    | `1`                                |
| `scheduling.tolerations`               | Tolerations for all pods (propagated via YAML anchors to global and nats) | `[]`  |
| `scheduling.nodeSelector`              | Node selector for all pods (propagated via YAML anchors) | `{}`  |
| `scheduling.affinity`                  | Affinity rules for all pods (propagated via YAML anchors) | `{}`  |
| `global.tolerations`                   | common tolerations for all pods (rocket.chat and all microservices) | []  |
| `global.annotations`                   | common annotations for all pods (rocket.chat and all microservices) | {}  |
| `global.nodeSelector`                  | common nodeSelector for all pods (rocket.chat and all microservices) | {}  |
| `global.affinity`                      | common affinity for all pods (rocket.chat and all microservices) | {}  |
| `tolerations`                          | tolerations for main rocket.chat pods (the `meteor` service) | [] |
| `microservices.enabled`                | Use [microservices](https://docs.rocket.chat/quick-start/installing-and-updating/micro-services-setup-beta) architecture                                                                                                                                                                                                                                                                                                                                       | `false`                            |
| `microservices.streamHub.enabled`      | Enable the Stream Hub microservice. **DEPRECATED**: Disabled by default for versions >= 7.7.3. Cannot be enabled for versions >= 8.0.0 (completely removed). For versions < 7.7.3, enabled by default unless explicitly disabled. When enabled, automatically sets `DB_WATCHERS=true` on all services. | `false` (auto-enabled for < 7.7.3) |
| `microservices.presence.replicas`      | Number of replicas to run for the presence service                                                                                                                                                                                                                                                                                                                                                                                                                | `1`                                |
| `microservices.ddpStreamer.replicas`   | Number of replicas to run for the ddpStreamer service                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.account.replicas`      | Number of replicas to run for the account service                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.authorization.replicas` | Number of replicas to run for the authorization service                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.presence.tolerations`      | Pod tolerations | [] |
| `microservices.ddpStreamer.tolerations`   | Pod tolerations | [] |
| `microservices.streamHub.tolerations`     | Pod tolerations | [] |
| `microservices.account.tolerations`      | Pod tolerations | [] |
| `microservices.authorization.tolerations` | Pod tolerations | [] |
| `microservices.presence.annotations`      | Pod annotations | {} |
| `microservices.ddpStreamer.annotations`   | Pod annotations | {} |
| `microservices.streamHub.annotations`     | Pod annotations | {} |
| `microservices.account.annotations`      | Pod annotations | {} |
| `microservices.authorization.annotations` | Pod annotations | {} |
| `microservices.presence.nodeSelector`     | nodeSelector for the Pod | {} |
| `microservices.ddpStreamer.nodeSelector`  | nodeSelector for the Pod | {} |
| `microservices.streamHub.nodeSelector`    | nodeSelector for the Pod | {} |
| `microservices.account.nodeSelector`     | nodeSelector for the Pod | {} |
| `microservices.authorization.nodeSelector`| nodeSelector for the Pod | {} |
| `microservices.presence.affinity`      | Pod affinity | {} |
| `microservices.ddpStreamer.affinity`   | Pod affinity | {} |
| `microservices.streamHub.affinity`     | Pod affinity | {} |
| `microservices.account.affinity`      | Pod affinity | {} |
| `microservices.authorization.affinity` | Pod affinity | {} |
| `readinessProbe.enabled`               | affinity for the Pod | [] |                                                                                                                                                                                                                                                                                                                                                                                                                             | `true`                             |
| `readinessProbe.initialDelaySeconds`   | Delay before readiness probe is initiated                                                                                                                                                                                                                                                                                                                                                                                                                      | `10`                               |
| `readinessProbe.periodSeconds`         | How often to perform the probe                                                                                                                                                                                                                                                                                                                                                                                                                                 | `15`                               |
| `readinessProbe.timeoutSeconds`        | When the probe times out                                                                                                                                                                                                                                                                                                                                                                                                                                       | `5`                                |
| `readinessProbe.failureThreshold`      | Minimum consecutive failures for the probe                                                                                                                                                                                                                                                                                                                                                                                                                     | `3`                                |
| `readinessProbe.successThreshold`      | Minimum consecutive successes for the probe                                                                                                                                                                                                                                                                                                                                                                                                                    | `1`                                |
| `registrationToken`                    | Registration Token for [Rocket.Chat Cloud ](https://cloud.rocket.chat)                                                                                                                                                                                                                                                                                                                                                                                         | ""                                 |
| `service.annotations`                  | Annotations for the Rocket.Chat service                                                                                                                                                                                                                                                                                                                                                                                                                        | `{}`                               |
| `service.labels`                       | Additional labels for the Rocket.Chat service                                                                                                                                                                                                                                                                                                                                                                                                                  | `{}`                               |
| `service.type`                         | The service type to use                                                                                                                                                                                                                                                                                                                                                                                                                                        | `ClusterIP`                        |
| `service.port`                         | The service port                                                                                                                                                                                                                                                                                                                                                                                                                                               | `80`                               |
| `service.nodePort`                     | The node port used if the service is of type `NodePort`                                                                                                                                                                                                                                                                                                                                                                                                        | `""`                               |
| `podDisruptionBudget.enabled`          | Enable or disable PDB for RC deployment                                                                                                                                                                                                                                                                                                                                                                                                                        | `true`                             |
| `podLabels`                            | Additional pod labels for the Rocket.Chat pods                                                                                                                                                                                                                                                                                                                                                                                                                 | `{}`                               |
| `podAnnotations`                       | Additional pod annotations for the Rocket.Chat pods                                                                                                                                                                                                                                                                                                                                                                                                            | `{}`                               |
| `federation.enabled`                   | Enable Rocket.Chat federation (through matrix) 
| `federation.host`                      | FQDN for your matrix instance
| `federation.image.repository`          | Image repository to use for federation image, defaults to `matrixdotorg`
| `federation.image.registry`            | Image registry to use for federation image, defaults to `docker.io`
| `federation.image.tag`                 | Image tag to use for federation image, defaults to `latest`
| `federation.persistence.enabled`       | Enabling persistence for matrix pod
| `postgresql.enabled`                   | Enabling postgresql for matrix (synapse), defaults to false, if false, uses sqlite
| `nats.nats.image`          | NATS container image (includes tag)                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `nats:2.12-alpine`                                |
| `nats.cluster.replicas`          | Number of replicas to run NATS                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `2`                                |
| `nats.exporter.enabled`          | Enable or Disable metrics collection for NATS                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `true`                                |
| `nats.enabled` | Enable or disabled NATS deploy, if using microservices and this is nil them it will be deployed | true for microservices (default), false for monolith |
| `nats.existingSecret.name` | Existing Secret name for an external NATS server | empty |
| `nats.existingSecret.key` | Existing Secret key for the `nats.existingSecret.name` containing the connection string | empty |
| `nats.podMonitor.enabled` | Enable NATS PodMonitor or service with scrape annotation | `true` |
| `nats.tolerations` | Tolerations for NATS pods (must be set explicitly for tainted nodes) | `[]` |
| `nats.nodeSelector` | Node selector for NATS pods (must be set explicitly) | `{}` |
| `nats.natsbox.tolerations` | Tolerations for NATS box pods (must be set explicitly for tainted nodes) | `[]` |
| `nats.natsbox.nodeSelector` | Node selector for NATS box pods (must be set explicitly) | `{}` |
Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install rocketchat -f values.yaml rocketchat/rocketchat
```

## Node Scheduling (Taints/Tolerations)

When deploying to nodes with taints, you need to configure tolerations for all components. This chart uses YAML anchors in the `global` block to simplify configuration - set tolerations once and they automatically apply to all components including NATS.

### Recommended: Edit values.yaml

The simplest approach is to copy `values.yaml` and uncomment the tolerations section:

```bash
# Copy the values file
cp rocketchat/values.yaml my-values.yaml

# Edit my-values.yaml - uncomment the tolerations in the global section

# Install with your values
helm install rocketchat rocketchat/rocketchat -f my-values.yaml
```

In `values.yaml`, uncomment these lines in the `global` section:

```yaml
global:
  ## Uncomment for tainted nodes:
  tolerations: &tolerations
    - key: "dedicated"
      operator: "Equal"
      value: "rocketchat"
      effect: "NoSchedule"
  nodeSelector: &nodeSelector
    dedicated: rocketchat
  ##
  ## Comment out or remove these defaults:
  # tolerations: &tolerations []
  # nodeSelector: &nodeSelector {}
```

The YAML anchors (`&tolerations`, `&nodeSelector`) propagate to NATS and other subcharts automatically.

> **Important:** YAML anchors only work within a single values file. If you use multiple `-f` files or `--set`, you must specify values for each component separately.

### Using --set (Alternative)

If you cannot use a values file, you can set tolerations individually:

```bash
helm install rocketchat ./rocketchat \
  --set 'global.tolerations[0].key=dedicated' \
  --set 'global.tolerations[0].operator=Equal' \
  --set 'global.tolerations[0].value=rocketchat' \
  --set 'global.tolerations[0].effect=NoSchedule' \
  --set 'nats.tolerations[0].key=dedicated' \
  --set 'nats.tolerations[0].operator=Equal' \
  --set 'nats.tolerations[0].value=rocketchat' \
  --set 'nats.tolerations[0].effect=NoSchedule' \
  --set 'nats.natsbox.tolerations[0].key=dedicated' \
  --set 'nats.natsbox.tolerations[0].operator=Equal' \
  --set 'nats.natsbox.tolerations[0].value=rocketchat' \
  --set 'nats.natsbox.tolerations[0].effect=NoSchedule'
```

> **Note:** The values file approach is much simpler. Use `--set` only when you cannot use a values file.

### External Nats

This chart supports using an existing NATS server instead of deploying a new one. This is useful when you have a shared NATS infrastructure or want to manage NATS separately from your Rocket.Chat deployment.

#### Using an External NATS Server

To use an external NATS server, you need to:

1. **Create a Kubernetes Secret** containing the NATS connection string:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-nats-secret
  namespace: rocketchat
type: Opaque
data:
  # Base64 encoded NATS connection string
  # Example: nats://user:password@nats-server:4222
  nats-url: bmF0czovL3VzZXI6cGFzc3dvcmRAbmF0cy1zZXJ2ZXI6NDIyMg==
```

2. **Configure the chart** to use the external NATS server:

```yaml
# Disable the built-in NATS deployment
nats:
  enabled: false
  existingSecret:
    name: "my-nats-secret"
    key: "nats-url"
```

### Stream Hub Microservice Deprecation

> **IMPORTANT**: As of Rocket.Chat version 7.7.3, the Stream Hub microservice is deprecated and disabled by default. As of version 8.0.0, it has been completely removed.

The Stream Hub microservice (`microservices.streamHub`) is being phased out:

- **Versions < 7.7.3**: Stream Hub is automatically enabled when using microservices architecture (unless explicitly disabled)
- **Versions >= 7.7.3 and < 8.0.0**: Stream Hub is disabled by default and should not be used for new deployments
- **Versions >= 8.0.0**: Stream Hub is completely removed and cannot be enabled (will always be disabled regardless of configuration)

If you need to enable Stream Hub for older versions (< 8.0.0) or backward compatibility, set:

```yaml
microservices:
  enabled: true
  streamHub:
    enabled: true
```

**Note**: When Stream Hub is enabled, the `DB_WATCHERS=true` environment variable is automatically set on all Rocket.Chat services to support database change stream watching.

### Database Setup

Rocket.Chat uses a MongoDB instance to presist its data.
By default, the [MongoDB](https://github.com/bitnami/charts/tree/master/bitnami/mongodb) chart is deployed and a single MongoDB instance is created as the primary in a replicaset.  
Please refer to this (MongoDB) chart for additional MongoDB configuration options.
If you are using chart defaults, make sure to set at least the `mongodb.auth.rootPassword` and `mongodb.auth.passwords` values. 

#### Using an External Database

This chart supports using an existing MongoDB instance. Use the `` configuration options and disable MongoDB with `--set mongodb.enabled=false`

### Configuring Additional Environment Variables

```yaml
extraEnv: |
  - name: MONGO_OPTIONS
    value: '{"ssl": "true"}'
```
### Specifying aditional volumes

Sometimes, it's needed to include extra sets of files by means of exposing 
them to the container as a mountpoint. The most common use case is the 
inclusion of SSL CA certificates. 

```yaml
extraVolumes: 
  - name: etc-certs
    hostPath:
    - path: /etc/ssl/certs
      type: Directory
extraVolumeMounts: 
  - mountPath: /etc/ssl/certs
    name: etc-certs   
    readOnly: true
```

### Increasing Server Capacity and HA Setup

To increase the capacity of the server, you can scale up the number of Rocket.Chat server instances across available computing resources in your cluster, for example,

```bash
$ kubectl scale --replicas=3 deployment/rocketchat
```

By default, this chart creates one MongoDB instance as a Primary in a replicaset.  This is the minimum requirement to run Rocket.Chat 1.x+.    You can also scale up the capacity and availability of the MongoDB cluster independently.  Please see the [MongoDB chart](https://github.com/bitnami/charts/tree/master/bitnami/mongodb) for configuration information.

For information on running Rocket.Chat in scaled configurations, see the [documentation](https://rocket.chat/docs/installation/docker-containers/high-availability-install/#guide-to-install-rocketchat-as-ha-with-mongodb-replicaset-as-backend) for more details.

### Adding tolerations, annotations, nodeSelector and affinity

To add common tolerations, annotations, nodeSelector and affinity to all deployments
```yaml
global:
  tolerations:
    - # here
  annotations:
      # here
  nodeSelector:
      # here
      # kubernetes.io/arch: amd64
  affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#       - matchExpressions:
#         - key: kubernetes.io/arch
#           operator: In
#           values:
#           - amd64
```

Override tolerations or annotations for each microservice by adding to respective block's configuration. For example to override the global tolerations and annotations for ddp-streamer pods,
```yaml
microservices:
  ddpStreamer:
    tolerations:
      - # add here
    annotations:
        # add here
  nodeSelector:
      # here
      # kubernetes.io/arch: amd64
  affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#       - matchExpressions:
#         - key: kubernetes.io/arch
#           operator: In
#           values:
#           - amd64
```

To override tolerations for `meteor` service, or the main rocket.chat deployment, add to the root tolerations key.
```yaml
tolerations:
  - # ...
```
To override annotations for `meteor` service, or the main rocket.chat deployment, add to the root podAnnotations key.
```yaml
podAnnotations:
    # add here
```
To override the nodeSelector for `meteor` service, or the main rocket.chat deployment, add to the root nodeSelector key.
```yaml
nodeSelector:
    # add here
```
To override the affinity for `meteor` service, or the main rocket.chat deployment, add to the root affinity key.
```yaml
  affinity:
#   nodeAffinity:
#     requiredDuringSchedulingIgnoredDuringExecution:
#       nodeSelectorTerms:
#       - matchExpressions:
#         - key: kubernetes.io/arch
#           operator: In
#           values:
#           - amd64
```
### Manage MongoDB and NATS nodeSelector and Affinity
If MongoDB and NATS own charts are used in the deployment, add the nodeSelector and Affinity to each service. Example:

```yaml
mongodb:
  enabled: true  
  nodeSelector:
   kubernetes.io/arch: amd64
  affinity:
   nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
nats:
  statefulSet:
    patch:
      - op: add
        path: /spec/template/spec/nodeSelector
        value:
          kubernetes.io/arch: amd64
      - op: add
        path: /spec/template/spec/affinity
        value:
          nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64
```
### Manage MongoDB secrets

This chart provides several ways to manage the Connection for MongoDB
* Values passed to the chart externalMongodbUrl
* An ExistingMongodbSecret containing the MongoURL
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  mongo-uri: mongodb://user:password@localhost:27017/rocketchat
```

## Federation

You can enable federation by setting `federation.enabled` to true.

You need to make sure you have two domains, one for rocket.chat another for matrix.

```yaml
host: <rocket.chat domain>
federation:
    host: <matrix domain>
```

Add the domains to ingress tls config

```yaml
ingress:
  tls:
    - secretName: <some secret>
      hosts:
        - <rocket.chat domain>
        - <matrix domain>
```

For production, postgres is recommended. Enabled postgres
```yaml
postgresql:
  enabled: true
```

For more details on configs, check [postgresql chart](https://artifacthub.io/packages/helm/bitnami/postgresql).

Since TLS is required, also make sure you have something like cert-manager is running on your cluster, and you add the annotations to the ingress with `ingress.annotations` (or whatever is the recommended way for your certificate issuer).

## hooks

To add custom annotations and labels to pods spawned by pre-upgrade hook

```yaml
hooks:
  preUpgrade:
    podAnnotatios: {} # here
    podLabels: {} # here
```

## Monitoring

This chart supports two Prometheus monitoring approaches: PodMonitor and ServiceMonitor. Each has distinct advantages depending on your monitoring needs:

#### PodMonitor (Recommended)
- Scrapes metrics directly from pods matching the selector
- Captures metrics from pods in all states (including not ready)
- Provides more comprehensive data for troubleshooting
- Better visibility into pod lifecycle events

#### ServiceMonitor
- Uses Kubernetes service selectors to discover pods
- Only scrapes metrics from pods that are ready and part of the service
- May miss metrics from pods in transitional states
- Simpler configuration but less detailed monitoring

#### External components

External components such as NATS and MongoDB by default have metrics enabled and collected by `podmonitors`, if the target cluster does not have Prometheus Operator CRDs, then a service will be created and annotated for Prometheus discovery.


- Nats:
```
nats:
  exporter:
    enabled: false
```

- MongoDB:
```
mongodb:
  metrics:
    enabled: false
```


For additional NATS configuration options, refer to the [official NATS Helm chart documentation](https://github.com/nats-io/k8s/tree/nats-1.3.1/helm/charts/nats).

#### TLDR

Choose PodMonitor if you need detailed pod-level metrics and troubleshooting data. Use ServiceMonitor if you only need metrics from healthy, service-ready pods.

## Upgrading

### To 5.4.3

Due to changes on upstream MongoDB chart, some variables have been renamed (previously deprecated), which, in turn changed how this chart generates its manifests. Values that need changing -
- `mongodb.auth.username` is no longer supported, and has been changed to `mongodb.auth.usernames` array. If you set it to something custom (defaults to `rocketchat`), make sure you update it to an array and the entry is the **first** entry in that array as that's what Rocket.Chat will use to connect to the database.
- `mongodb.auth.password` is no longer supported either and has been changed to `mongodb.auth.passwords` array. Update your values file to make it an array and make sure it's the first entry of that array.
- `mongodb.auth.database` is no longer supported either and has been changed to its plural version, `mongodb.auth.databases`. Update your values file, convert it to an array and make sure it's the first entry of that list.
- `mongodb.auth.rootUsername` and `mongodb.auth.rootPassword` are staying the same.

*`usernames`, `passwords` and `databases` arrays must be of the same length. Rocket.Chat chart will use the first entry for its mongodb connection string in `MONGO_URL`.*

On each chart update, the used image tag gets updated, **in most cases**. Same is true for the MongoDB chart we use as our dependency. Pre-5.4.3, we had been using the chart version 10.x.x, but starting 5.4.3, the dependency chart version has been bumped to the latest available version, 13.x.x. This chart defaults to mongodb 6.0.x as of the time of writing this.

As a warning, this chart will not handle MongoDB upgrades and will depend on the user to make sure it's running on the supported version. The upgrade will fail if any of the following requirements are not met -
- must not skip a MongoDB release. E.g. 4.2.x to 5.0.x will fail
- current `featureCompatibilityVersion` must be compatible with the version user is trying to upgrade to. E.g. if current database version and feature compatibility is 4.4 and 4.2 respectively, but user is trying to upgrade to 5.0, it'll fail

The chart will not check if the mongodb version is supported by the Rocket.Chat version considering deployments, that might occur in an airgapped environment. It is up to the user to make sure of that. Users can check Rocket.Chat's release notes to confirm that.

To get the currently deployed MongoDB version, the easiest method is to get into the mongo shell and running `db.version()`.

It is advised to pin your MongoDB dependency in the values file.
```yaml
mongodb:
  image:
    tag: # find from https://hub.docker.com/r/bitnami/mongodb/tags
```

References:
- [Run a shell inside a container (to check mongodb version)](https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/)
- [MongoDB upgrade official documentation](https://www.mongodb.com/docs/manual/tutorial/upgrade-revision/)
- [MongoDB helm chart options](https://artifacthub.io/packages/helm/bitnami/mongodb)

### To 6.13.0

**This is only applicable if you both, enabled federation in chart version >=6.8, and want to keep using lighttpd.**

IFF you manually enabled ingress.federation.serveWellKnown (which was a hidden setting) before, during upgrade, disable it once before enabling it again.

Chart contained a bug that would cause `wellknown` deployment to fail to update (illegal live modification of `matchLabels`).

### To 6.25.0

**This is only applicable if you are using Prometheus monitoring with ServiceMonitor.**

The chart has been updated to allow the use PodMonitor instead of ServiceMonitor for Prometheus metrics collection. If you were using ServiceMonitor before and you wan't to migrate from ServiceMonitor to PodMonitor instead. Here's how to migrate:

1. Remove the old ServiceMonitor configuration:
```yaml
serviceMonitor:
  enabled: true
  intervals:
    - 30s
  ports:
    - metrics
prometheusScraping:
  enabled: true
  port: 9100
```

2. Replace it with the new PodMonitor configuration:
```yaml
podMonitor:
  enabled: true
  interval: 30s
prometheusScraping:
  enabled: true
  port: "9100"
  msPort: "9458"
```

The functionality remains the same, but the implementation has been updated to use the more granular PodMonitor resource type. This change provides better visibility when using multiple replicas for each service.
