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
| `externalMongodbOplogUrl`              | MongoDB OpLog URL if using an externally provisioned MongoDB. Required if `externalMongodbUrl` is set                                                                                                                                                                                                                                                                                                                                                          | `""`                               |
| `mongodb.enabled`                      | Enable or disable MongoDB dependency. Refer to the [stable/mongodb docs](https://github.com/bitnami/charts/tree/master/bitnami/mongodb#configuration) for more information                                                                                                                                                                                                                                                                                     | `true`                             |
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
| `global.tolerations`                   | common tolerations for all pods (rocket.chat and all microservices) | []  |
| `global.annotations`                   | common annotations for all pods (rocket.chat and all microservices) | {}  |
| `tolerations`                          | tolerations for main rocket.chat pods (the `meteor` service) | [] |
| `microservices.enabled`                | Use [microservices](https://docs.rocket.chat/quick-start/installing-and-updating/micro-services-setup-beta) architecture                                                                                                                                                                                                                                                                                                                                       | `false`                            |
| `microservices.presence.replicas`      | Number of replicas to run for the given service                                                                                                                                                                                                                                                                                                                                                                                                                | `1`                                |
| `microservices.ddpStreamer.replicas`   | Idem                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.streamHub.replicas`     | Idem                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.accounts.replicas`      | Idem                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.authorization.replicas` | Idem                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.nats.replicas`          | Idem                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `1`                                |
| `microservices.presence.tolerations`      | Pod tolerations | [] |
| `microservices.ddpStreamer.tolerations`   | Pod tolerations | [] |
| `microservices.streamHub.tolerations`     | Pod tolerations | [] |
| `microservices.accounts.tolerations`      | Pod tolerations | [] |
| `microservices.authorization.tolerations` | Pod tolerations | [] |
| `microservices.presence.annotations`      | Pod annotations | {} |
| `microservices.ddpStreamer.annotations`   | Pod annotations | {} |
| `microservices.streamHub.annotations`     | Pod annotations | {} |
| `microservices.accounts.annotations`      | Pod annotations | {} |
| `microservices.authorization.annotations` | Pod annotations | {} |
| `readinessProbe.enabled`               | Turn on and off readiness probe                                                                                                                                                                                                                                                                                                                                                                                                                                | `true`                             |
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

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install rocketchat -f values.yaml rocketchat/rocketchat
```

### Database Setup

Rocket.Chat uses a MongoDB instance to presist its data.
By default, the [MongoDB](https://github.com/bitnami/charts/tree/master/bitnami/mongodb) chart is deployed and a single MongoDB instance is created as the primary in a replicaset.  
Please refer to this (MongoDB) chart for additional MongoDB configuration options.
If you are using chart defaults, make sure to set at least the `mongodb.auth.rootPassword` and `mongodb.auth.passwords` values. 
> **WARNING**: The root credentials are used to connect to the MongoDB OpLog

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

### Adding tolerations and annotations

To add common tolerations and annotations to all deployments
```yaml
global:
  tolerations:
    - # here
  annotations:
      # here
```

Override tolerations or annotations for each microservice by adding to respective block's configuration. For example to override the global tolerations and annotations for ddp-streamer pods,
```yaml
microservices:
  ddpStreamer:
    tolerations:
      - # add here
    annotations:
        # add here
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


### Manage MongoDB secrets

This chart provides several ways to manage the Connection for MongoDB
* Values passed to the chart (externalMongodbUrl, externalMongodbOplogUrl)
* An ExistingMongodbSecret containing the MongoURL and MongoOplogURL
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  mongo-uri: mongodb://user:password@localhost:27017/rocketchat
  mongo-oplog-uri: mongodb://user:password@localhost:27017/local?replicaSet=rs0&authSource=admin
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

## Upgrading

### To 5.4.3

Due to changes on upstream MongoDB chart, some variables have been renamed (previously deprecated), which, in turn changed how this chart generates its manifests. Values that need changing -
- `mongodb.auth.username` is no longer supported, and has been changed to `mongodb.auth.usernames` array. If you set it to something custom (defaults to `rocketchat`), make sure you update it to an array and the entry is the **first** entry in that array as that's what Rocket.Chat will use to connect to the database.
- `mongodb.auth.password` is no longer supported either and has been changed to `mongodb.auth.passwords` array. Update your values file to make it an array and make sure it's the first entry of that array.
- `mongodb.auth.database` is no longer supported either and has been changed to its plural version, `mongodb.auth.databases`. Update your values file, convert it to an array and make sure it's the first entry of that list.
- `mongodb.auth.rootUsername` and `mongodb.auth.rootPassword` are staying the same.

*`usernames`, `passwords` and `databases` arrays must be of the same length. Rocket.Chat chart will use the first entry for its mongodb connection string in `MONGO_URL` and `MONGO_OPLOG_URL`.*

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
