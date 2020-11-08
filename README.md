Sourcehawk OpenFaaS Community Cluster
-------------------------------------

[![Sourcehawk Scan](https://github.com/optum/sourcehawk-openfaas-community-cluster/workflows/Sourcehawk%20Scan/badge.svg)](https://github.com/optum/sourcehawk-openfaas-community-cluster/actions) 
![OSS Lifecycle](https://img.shields.io/osslifecycle/optum/sourcehawk-openfaas-community-cluster) 
[![OpenFaaS](https://img.shields.io/badge/openfaas-cloud-blue.svg)](https://www.openfaas.com)

This repository hosts the deployment configuration for deploying Sourcehawk OpenFaaS functions to OpenFaaS Community Cluster.

### Configuration

The `stack.yml` file is the main configuration for the OpenFaas community cluster.

#### Deployments

Deployments are triggered automatically on `push` events to this repository's `master` branch.  This 
is enabled through the `OpenFaaS Cloud Community Cluster` app integration.  The default branch is still 
`main`, and merges from `main` to `master` will start the deployment automatically.

#### Cluster Dashboard

https://system.o6s.io/dashboard/Optum

#### OpenFaaS Community Cluster Docs

- https://docs.openfaas.com/openfaas-cloud/user-guide
- https://github.com/openfaas/community-cluster/tree/master/docs

### Development

#### FaaS CLI Installation
https://docs.openfaas.com/cli/install/

#### Building

```sh
faas build
```