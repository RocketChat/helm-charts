# helm-charts

This is helm repository for RocketChat charts. Follow the steps below to start deploying any of them in your Kubernetes cluster.

## Usage

### Helm3

Be sure you have helm3 binary insalled, add this repository and install rocketchat chart:

```bash
$ helm repo add rocketchat https://rocketchat.github.io/helm-charts
```

And check our rocketchat server helm chart folder for more instructions [here](https://github.com/RocketChat/helm-charts/tree/master/rocketchat)

### Helm2

We still support helm2, this will only work using helm2 binary and tiller deployment running in your k8s cluster:

```bash
$ helm repo add rocketchat https://rocketchat.github.io/helm-charts
```

```bash
$ helm install --set mongodb.mongodbUsername=rocketchat,mongodb.mongodbPassword=changeme,mongodb.mongodbDatabase=rocketchat,mongodb.mongodbRootPassword=root-changeme --name my-rocketchat rocketchat/rocketchat --version 3.0.0
```


