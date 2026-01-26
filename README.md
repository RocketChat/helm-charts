# helm-charts

This is helm repository for RocketChat charts. Follow the steps below to start deploying any of them in your Kubernetes cluster.

## Important Note!

If you are currently using the built in mongo and have not already switched to an external mongo please see our forum post:

https://forums.rocket.chat/t/action-required-helm-chart-moving-from-bitnami-to-official-mongodb-chart/22679

We will be removing the built in mongo using Bitnami in susequent versions.

## Usage

Be sure you have helm3 binary insalled, add this repository and install rocketchat chart:

```bash
$ helm repo add rocketchat https://rocketchat.github.io/helm-charts
```

And check our rocketchat server helm chart folder for more instructions [here](https://github.com/RocketChat/helm-charts/tree/master/rocketchat)


## Contributing

We welcome contributions to the RocketChat Helm charts! This section provides information on how to run tests, add new tests, and the tools used in our testing infrastructure.

### Prerequisites

Before contributing, ensure you have the following tools installed:

- **Helm 3**: For chart management and testing
- **Docker**: For running mock services and containerized tests
- **kubectl**: For Kubernetes cluster interaction
- **BATS (Bash Automated Testing System)**: Already included as a submodule in the `bats/` directory

### Testing Infrastructure

Our testing setup uses several tools and frameworks:

- **BATS**: Bash Automated Testing System for writing and running tests
- **BATS-Detik**: Kubernetes-specific BATS library for testing Kubernetes resources
- **KWOK**: Kubernetes WithOut Kubelet for lightweight cluster testing
- **KinD**: Kubernetes in Docker for local cluster testing
- **Docker Compose**: For running mock services

### Running Tests

#### Quick Start

The easiest way to run tests is using the Task runner:

```bash
# Run tests using KWOK (lightweight, recommended for development)
./task.bash clean rocketchat microservices mock
./task.bash clean rocketchat microservices mock

# Run tests using KinD (full Kubernetes cluster)
./task.bash clean rocketchat microservices cluster
./task.bash clean rocketchat microservices cluster
```

#### Test Modes

The tests support two deployment modes:

- **Monolith**: Single RocketChat instance with all services
- **Microservices**: Distributed RocketChat deployment with separate services

### Adding New Tests

#### Test Structure

Tests are located in `rocketchat/tests/` and use BATS framework:

- `rocketchat.bats`: Main test suite with deployment and assertion tests
- `common.bash`: Common test utilities and functions
- `run.bash`: Test execution script

#### Writing New Tests

1. **Test File Location**: Add new test files in `rocketchat/tests/` directory
2. **BATS Syntax**: Use standard BATS syntax with test tags for organization
3. **Test Tags**: Use tags to categorize tests:
   - `pre`: Pre-deployment checks
   - `deploy`: Deployment tests
   - `assertion`: Resource verification tests
   - `monolith`/`microservices`: Mode-specific tests

Example test structure:

```bash
#!/bin/bash

load "../../bats/common.sh"
load "../../bats/kubernetes_common.sh"
load "common.bash"

# bats test_tags=assertion
@test "verify custom pod configuration" {
  test_pods \
    "somepod-0" \
}
```

#### Test Utilities

The test framework provides several utilities:

- **Kubernetes assertions**: Use functions from `bats/kubernetes_common.sh`
- **Common utilities**: Use functions from `bats/common.sh`
- **Chart-specific utilities**: Use functions from `rocketchat/tests/common.bash`

### Continuous Integration

Tests are automatically run in GitHub Actions on:
- Pull requests affecting `rocketchat/`, `bats/`, `mock/`, or test workflows
- Manual workflow dispatch
- Workflow calls from other repositories

The CI pipeline runs tests for both monolith and microservices modes using both KWOK and KinD clusters.

### Adding Kubernetes Operators

When you need to test functionality that depends on Kubernetes operators (such as MongoDB CRDs), you must deploy the operator container as part of the docker-compose stack alongside KWOK.

#### Steps to Add an Operator

1. **Deploy the operator** in a test Kubernetes cluster
2. **Inspect the operator pod** to gather configuration:
   ```bash
   kubectl describe pod <operator-pod-name> -n <namespace>
   ```
3. **Extract the required information**:
   - Container image and tag
   - Command and arguments
   - Environment variables
   - Volume mounts (if any)

4. **Add the operator to `docker-compose.yml`**:
```yaml
   operator-name:
     image: operator-image:tag
     command: ["extracted-command"] # some operators won't need to change this
     environment:
       - KUBERNETES_MASTER=https://kwok-kwok-controller:10250
       - KUBECONFIG=/kubeconfig-volume/kubeconfig.yaml
       # Add other environment variables from the pod description
     volumes:
      - kubeconfig-volume:/kubeconfig-volume
     networks:
       - kwok-network
      depends_on:
        kubeconfig:
          condition: service_completed_successfully
```

5. **Verify the operator** is running:
   ```bash
   docker-compose -f mock/compose.yaml ps
   docker-compose -f mock/compose.yaml logs operator-name
   ```

#### Required Environment Variables

All operators need these essential environment variables to connect to the KWOK cluster:

- `KUBERNETES_MASTER`: Points to the KWOK controller (typically `https://kwok-kwok-controller:10250`)
- `KUBECONFIG`: Path to the kubeconfig file (typically `/root/.kube/config`)

#### Example: MongoDB Community Operator

```yaml
mongodb-operator:
  image: quay.io/mongodb/mongodb-kubernetes-operator:0.7.6
  command: ["/usr/local/bin/entrypoint"]
  environment:
    - KUBERNETES_MASTER=https://kwok-kwok-controller:10250
    - KUBECONFIG=/root/.kube/config
    - WATCH_NAMESPACE=default
    - MANAGED_SECURITY_CONTEXT=true
  volumes:
    - ./kubeconfig:/root/.kube/config:ro
  networks:
    - kwok
  depends_on:
    - kwok-controller
```

#### Troubleshooting Operators

- **Connection issues**: Verify the `KUBERNETES_MASTER` URL matches your KWOK controller service name
- **Permission errors**: Ensure the operator has necessary RBAC permissions in your test cluster
- **CRD not found**: Apply CRD definitions before starting the operator
- **Operator logs**: Check logs with `docker-compose logs -f operator-name`

### Contributing Guidelines

1. **Test Coverage**: Ensure new features include appropriate tests
2. **Test Tags**: Use appropriate tags to categorize your tests
3. **Documentation**: Update this section if you add new testing tools or procedures
4. **CI Compatibility**: Ensure tests work in the CI environment
5. **Local Testing**: Test your changes locally before submitting PRs

For more detailed information about the RocketChat chart, see the [chart-specific README](https://github.com/RocketChat/helm-charts/tree/master/rocketchat).
