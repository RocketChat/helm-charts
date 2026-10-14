# Rocket.Chat's Native Video Conference LiveKit Helm Chart

> [!IMPORTANT]
> This is an __experimental__ chart. It wasn't extensively tested and there
> may be dragons. Be advised!

## Preamble

This chart deploys a single [LiveKit](https://livekit.io)
server, the media server behind Rocket.Chat's native video conference, next to a
workspace. It's the Kubernetes counterpart of
[Deploying LiveKit next to Rocket.Chat](https://github.com/RocketChat/Rocket.Chat/blob/develop/docs/features/native-video-conference/deployment.md),
and is meant to be installed as a launchcontrol plugin, although a plain `helm install`
works too.

> [!NOTE]
> LiveKit calls need the `video-conference-native` license module, on top of
> `videoconference-enterprise`. Without them, Rocket.Chat doesn't offer LiveKit,
> however well this chart is deployed.

## What gets deployed

LiveKit has two faces:

* **Signalling** (HTTP/WebSocket), served through the ingress at `host`, e.g.
  `livekit.chat.foobar.org`. This is the URL Rocket.Chat hands to clients.
* **Media** (WebRTC), raw UDP on a single port (`media.udpPort`, 7882), which
  can't go through the ingress and is exposed with its own `LoadBalancer`
  (an NLB on AWS) or `NodePort` Service.

For a release called `foobar`, this creates:

* A `Deployment` called `foobar-rocketchat-livekit` (one replica, see [Scaling](#scaling));
* A `ClusterIP` service called `foobar-rocketchat-livekit` (signalling and metrics);
* A `LoadBalancer` service called `foobar-rocketchat-livekit-media` (media);
* An `Ingress` called `foobar-rocketchat-livekit`, with a cert-manager certificate;
* A `ConfigMap` holding `livekit.yaml`;
* A `Secret` called `livekit-credentials`, holding the API key pair and the URL;
* A `ServiceMonitor`, if the Prometheus Operator CRDs are installed.

## The API key pair

LiveKit and Rocket.Chat share an API key and secret. Unless `credentials.apiKey`
and `credentials.apiSecret` are set, the chart generates a pair on install and
reads it back on upgrades. The `livekit-credentials` Secret is annotated with
`helm.sh/resource-policy: keep`, so it outlives an uninstall and a reinstall picks
it up again. Delete it by hand to rotate the pair (then restart LiveKit and Rocket.Chat).

To bring your own Secret (a SealedSecret, for instance), set `credentials.existingSecret`.
It must hold the `apiKey`, `apiSecret` and `url` (`wss://<host>`) keys. The launchcontrol
Plugin looks for a Secret called `livekit-credentials`, so name it that, or update the
Plugin to match.

## The media address

LiveKit must tell clients which IP to send media to, and in Kubernetes that's the
media load balancer's, not anything the pod can see. The chart offers three ways,
from most to least preferred:

1. `media.nodeIP`: the public IPv4 itself, e.g. an EIP allocated to the NLB with
   `service.beta.kubernetes.io/aws-load-balancer-eip-allocations`.
2. `media.externalAddress` (the default): a FQDN pointing at the media load balancer,
   e.g. `rtc.chat.foobar.org` as a CNAME to the NLB's hostname. LiveKit resolves it
   when it starts, and waits (up to 10 minutes) for it to resolve. If the address
   changes later on, restart the pod.
3. Neither: LiveKit finds its public IP through STUN, which is only right when the
   pod's egress IP is also the one clients reach (e.g. `hostNetwork`).

> [!NOTE]
> An NLB spanning several availability zones has an IP per zone, and LiveKit only
> advertises one. With `externalTrafficPolicy: Local`, only the LiveKit pod's node
> is a healthy target, so media sent to another zone's IP would go nowhere. That's
> why the chart enables cross-zone load balancing on the NLB
> (`service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled`),
> at the cost of AWS's inter-zone data transfer. To avoid that cost, set it to
> `"false"` in `media.serviceAnnotations` and either pin the pod to the zone of the
> advertised IP or use an EIP in a single zone.

With `media.serviceType: NodePort`, the node port is the port LiveKit advertises,
so `media.udpPort` must be within the cluster's node port range (30000-32767 by default).

## Installing as a launchcontrol plugin

Apply [`plugin.yaml`](./plugin.yaml), which defines a cluster-wide `Plugin` called
`livekit`, then enable it on a workspace:

```yaml
apiVersion: launchcontrol.cloud.rocket.chat/v1alpha1
kind: Workspace
metadata:
  name: acme
spec:
  # [...]
  plugins:
    - name: livekit
      # values:
      #   media.nodeIP: "203.0.113.10"
```

launchcontrol installs the chart in the workspace's namespace as
`plugin-livekit-<workspace>`, with:

* `host` set to `livekit.<workspace>.<baseDomain>`;
* `media.externalAddress` set to `rtc.<workspace>.<baseDomain>`.

and configures Rocket.Chat through `OVERWRITE_SETTING_*` environment variables, so
these settings become read-only in the admin UI:

| Setting | Value |
| --- | --- |
| `VideoConf_Conference_Window_Enabled` | `true` |
| `VideoConf_LiveKit_Enabled` | `true` |
| `VideoConf_LiveKit_Url` | `url` from the `livekit-credentials` Secret |
| `VideoConf_LiveKit_Api_Key` / `VideoConf_LiveKit_Api_Secret` | `apiKey` / `apiSecret` from the same Secret |
| `VideoConf_Default_Provider` | `livekit` |

Then point the DNS:

* `livekit.<workspace>.<baseDomain>` to the same place the workspace points to (the ingress);
* `rtc.<workspace>.<baseDomain>` as a CNAME to the media load balancer:

```
$ kubectl -n acme get svc plugin-livekit-acme-rocketchat-livekit-media
```

Workspace values are strings, so pass booleans as `"true"`/`"false"`. The chart
reads them as such.

> [!NOTE]
> Rocket.Chat's pods read their LiveKit settings from the `livekit-credentials`
> Secret, so new Rocket.Chat pods wait for it on the first install (until
> launchcontrol's Helm job creates it). The Secret is kept around for the same
> reason: launchcontrol keeps injecting the plugin's environment variables while
> it's listed on the workspace, even with `disabled: true`. To turn LiveKit off,
> remove the plugin from the workspace instead.

## Installing with Helm

Copy `values.example.yaml` to `values.foobar.yaml` (or any other name you might
prefer), edit it, then:

```sh
helm install -f values.foobar.yaml --namespace foobar foobar .
```

Configure Rocket.Chat under **Administration → Settings → Conference Call** as
in the table above, using `wss://<host>` and the pair from the Secret:

```sh
kubectl -n foobar get secret livekit-credentials -o jsonpath='{.data.apiKey}' | base64 -d
kubectl -n foobar get secret livekit-credentials -o jsonpath='{.data.apiSecret}' | base64 -d
```

## Verifying

1. `curl -s https://livekit.chat.foobar.org` answers `OK`: signalling is reachable.
2. The pod's log says `Advertising <IP> (<externalAddress>) to clients`, and that IP
   is the media load balancer's.
3. Start a call in a DM, then join from a second user **on a different network**
   (a phone on cellular data). A LAN test proves nothing about the media path.

| Symptom | Likely cause |
| --- | --- |
| No LiveKit option in the provider list | The `video-conference-native` license module is missing |
| Call window opens but nobody connects | The ingress or the `livekit.` DNS record is wrong |
| Connected, no audio/video | UDP `media.udpPort` doesn't reach the pod, or the advertised IP is wrong (see [the warning above](#the-media-address)) |
| Pod not ready, logging `Waiting for ... to resolve` | The `rtc.` DNS record doesn't exist yet |

## TURN (restrictive networks)

Clients that can't reach UDP at all need LiveKit's TURN relay over TLS. Set
`turn.enabled: "true"`, and:

* a certificate for `turn.host` (defaults to `media.externalAddress`), either from
  cert-manager (`turn.certManager.enabled`, which needs a DNS-01 capable issuer, as
  the host points at the media load balancer and not at the ingress) or your own
  `kubernetes.io/tls` Secret (`turn.existingTlsSecret`);
* a cluster that supports mixed-protocol `LoadBalancer` Services, as `turn.tlsPort`
  (TCP) is exposed next to the media port (UDP). The same goes for `media.tcp.enabled`.

## Scaling

One LiveKit node handles many rooms. The chart runs exactly one, replaced with a
`Recreate` strategy, so updating it drops ongoing calls. A multi-node LiveKit needs
Redis and a media address per node, which this chart doesn't do.

LiveKit warns about a small UDP receive buffer on most nodes. `net.core.rmem_max`
isn't a namespaced sysctl, so raise it on the nodes themselves (to `5000000`) for
busy deployments.

## Other settings

Anything else from [LiveKit's configuration](https://github.com/livekit/livekit/blob/master/config-sample.yaml)
goes under `config`, merged over what the chart generates:

```yaml
config:
  room:
    empty_timeout: 300
```
