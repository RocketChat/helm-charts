# helm-charts

This is helm repository for RocketChat charts. Follow the steps below to start deploying any of them in your Kubernetes cluster.

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

### Troubleshooting

#### Common Issues

1. **Submodules not initialized**: Run `./task.bash submodules`
2. **Docker not running**: Ensure Docker daemon is running
3. **Port conflicts**: Check if required ports are available
4. **Cluster already exists**: Verify with `docker ps` and `king get cluster` if there is no leftovers from a failed run

#### Environment Variables

Key environment variables for testing:

- `ROCKETCHAT_HOST`: Hostname for RocketChat (default: rocketchat.example.com)
- `ROCKETCHAT_TAG`: RocketChat image tag (default: 7.7.1)
- `HELM_TAG`: Chart version for testing (default: 0.0.0)
- `POD_RETRIES`: Number of retries for pod checks (default: 5)
- `POD_RETRY_INTERVAL`: Interval between retries in seconds (default: 30)

### Contributing Guidelines

1. **Test Coverage**: Ensure new features include appropriate tests
2. **Test Tags**: Use appropriate tags to categorize your tests
3. **Documentation**: Update this section if you add new testing tools or procedures
4. **CI Compatibility**: Ensure tests work in the CI environment
5. **Local Testing**: Test your changes locally before submitting PRs

For more detailed information about the RocketChat chart, see the [chart-specific README](https://github.com/RocketChat/helm-charts/tree/master/rocketchat).