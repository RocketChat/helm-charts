# Rocket.Chat's Team Collaboration VoIP Helm Chart

> [!IMPORTANT]
> This is an __experimental__ chart. This is currently a MVP and is under 
> active development. As such, it wasn't extensively tested and there may 
> be dragons. Be advised! 

## Preamble

This chart **doesn't** deploy Rocket.Chat. In fact, it doesn't even 
require an workspace to be running. All it does is to deploy FreeSWITCH and 
optionally Drachtio to the specified namespace. The way Rocket.Chat is deployed 
is up to you, but for it to work, the instance has to be able to talk with 
FreeSWITCH's API. 

In this document, we're assuming you're deploying directly to a namespace 
in which there's already a workspace running and exposed to the internet. 

## Preparation

Let's say you have an namespace called `foobar-workspace`, and that you got 
a Rocket.Chat instance there, running micro-services and exposed under the 
address `chat.foobar.org`. Also, assume we're using Træfik as the ingress 
controller in this environment. 

Copy `values.example.yaml` file to `values.foobar.yaml` (or any other name 
you might prefer), then edit the file as you wish. This file contains only 
a handful of reasonable settings that you generally want to change, follow 
the comments to understand what each setting does. When done, save the file 
and make sure Helm is installed. 

```
$ helm version
version.BuildInfo{Version:"v3.18.4", GitCommit:"d80839cf37d860c8aa9a0503fe463278f26cd5e2", GitTreeState:"clean", GoVersion:"go1.24.4"}
```

## Installation

If all goes well, you can now run `helm install`. 

```sh
helm install -f values.example.yaml --namespace teste foobar .
```

> [!INFO]
> You can use `helm install --dry-run [...]` if you want to inspect the generated files before actually applying them. 

This should create: 
* A `Deployment` called `foobar-rocketchat-voip`; 
* A `LoadBalancer` service called `foobar-rocketchat-voip-rtp`; 
* A `ClusterIP` service called `foobar-rocketchat-voip`; 
* A `Pod`, as a result of the aforementioned deployment (seen bellow.) 

```
$ kubectl -n foobar get pods
NAME                                                 READY   STATUS    RESTARTS   AGE
pod/foobar-rocketchat-voip-76d87bc887-l7m42   1/1     Running   0          17m
[...]
```

FreeSWITCH is now running. 

## Architecture Support

This chart supports both legacy and new architecture modes:

### New Architecture (Default)
- **Drachtio**: Enabled by default (`drachtio.enabled: true`)
- **USE_LEGACY_ARCH**: Set to `false` on FreeSWITCH
- **DRACHTIO_DOMAIN**: Set to the drachtio service name for FreeSWITCH integration
- **Prometheus Monitoring**: Both FreeSWITCH and Drachtio have ServiceMonitors

### Legacy Architecture
Set `useLegacyArch: true` to use the legacy architecture:
- **Drachtio**: Automatically disabled
- **USE_LEGACY_ARCH**: Set to `true` on FreeSWITCH
- **Prometheus Monitoring**: Only FreeSWITCH ServiceMonitor is created

## Drachtio (New Architecture Only)

Drachtio provides a SIP server framework for Node.js applications and is automatically enabled for the new architecture.

- **Admin Port**: 9022 (for client connections)
- **SIP Port**: 5060 (UDP)
- **Image**: `drachtio/drachtio-server:latest`
- **Resources**: Configurable memory and CPU limits
- **Service Type**: ClusterIP with None clusterIP (headless service)

### Configuration

Key configuration options in `values.yaml`:

```yaml
# Architecture selection
useLegacyArch: false  # Set to true for legacy architecture

# Drachtio (new architecture only)
drachtio:
  enabled: true
  secret: "SECRETPASSWORD"  # Change this!
  config:
    logging:
      level: info
    sip:
      contacts:
        - "sip:*;transport=udp"
      udpMtu: 8192
    monitoring:
      prometheus:
        enabled: true  # ServiceMonitor created automatically

# FreeSWITCH Prometheus monitoring
freeswitch:
  monitoring:
    prometheus:
      enabled: true  # ServiceMonitor created automatically
```

### Services Created

**Always created:**
* A `Deployment` called `foobar-rocketchat-voip` (FreeSWITCH)
* A `ClusterIP` service called `foobar-rocketchat-voip` (FreeSWITCH)
* A `LoadBalancer` service called `foobar-rocketchat-voip-rtp` (RTP ports)
* A `ServiceMonitor` called `foobar-rocketchat-voip-freeswitch` (if monitoring enabled)

**New Architecture only (`useLegacyArch: false`):**
* A `Deployment` called `foobar-rocketchat-voip-drachtio`
* A `ClusterIP` service called `foobar-rocketchat-voip-drachtio`
* A `Secret` containing the Drachtio configuration
* A `ServiceMonitor` called `foobar-rocketchat-voip-drachtio` (if monitoring enabled)

## Accessing FreeSWITCH

The SIP WebSocket should be accessible at `voip.chat.foobar.org`, make sure 
that the DNS points to the same place `chat.foobar.org` does. 

### RTP

Since RTP is not HTTP-based, but a raw UDP protocol, the FreeSWITCH ports 
responsible for it should be directly exposed. There are several ways to 
do it, but this chart was tested using only one, thus far. 

By default, this chart uses the `LoadBalancer` service. On AWS, this is 
called «Network Load Balancer» or NLB. Creating such an object on a 
Elastic Kubernetes Services (EKS) cluster, causes the load balancer to 
get it's own external address, as we can see here: 

```
$ kubectl -n foobar get svc foobar-rocketchat-voip-rtp 
NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                                                                                                                                                                                          AGE
foobar-rocketchat-voip-rtp   LoadBalancer   172.30.210.119   aaf2c3919b45d4a1d8c76b29d0ac9beb-b6c16c2368089984.elb.us-east-1.amazonaws.com   20000:31997/UDP,[...],20046:30636/UDP   68s
```

Be sure to point `rtp.chat.foobar.org` as a CNAME to that immense address 
listed on the `EXTERNAL-IP` column. 

If you're running on other Kubernetes platforms, the way the cluster deals 
with this object may differ. `k3d`, for instance, binds it to it's IP on 
Docker network, so it probably shares it with other LB's you might have on 
the same cluster, like Træfik's, for example. In this case, the DNS addresses 
would all point to the same place (of course, 172.19.0.3 is a RFC1918 address, 
so you would still have to expose it, but exposing `k3d` edges on public 
network is beyond the scope of this document.)

```
default                plugin-voip-voip-...     LoadBalancer   10.43.239.204   172.19.0.3    20000:31824/UDP,[...],20046:32652/UDP   4h35m
kube-system            traefik                  LoadBalancer   10.43.161.144   172.19.0.3    80:31389/TCP,443:30313/TCP              2d8h
```

## Configuring Rocket.Chat

cf. [Rocket.Chat Configuration](https://github.com/RocketChat/Voip.Server.Official.Image/blob/main/README.md#rocketchat-configuration)
section of the main `README.md`. 

Considering we're running Rocket.Chat in the same namespace as FreeSWITCH's, 
`FreeSWITCH Host` setting should point to the `ClusterIP` service name, that 
is: `foobar-rocketchat-voip`, in our particular case. 