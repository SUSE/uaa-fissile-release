# UAA fissile release

This repository contains the files necessary to run a standalone UAA using fissile.
It is roughly equivalent to doing the same with BOSH.

## Prerequisites

### A Kubernetes cluster

[hcf.git] has sample instructions for setting one up locally via hyperkube; 
other methods of deploying Kubernetes should work as well.

[hcf.git]: https://github.com/hpcloud/hcf/tree/master/docs/kube.md

### docker
Docker is required for [fissile] to build images.

### fissile

[fissile] is required to build the docker images and configuration.

[fissile]: https://github.com/hpcloud/fissile

### direnv
[direnv] is recommended, but manually sourcing the `.envrc` should work just as
well.

[direnv]: https://github.com/direnv/direnv/

### Ruby
Ruby 2.3 is needed to install some of the releases.  Using [rbenv] with
[ruby-build] should work, but if you have issues [ruby-install] is also an
option.

[rbenv]: https://github.com/sstephenson/rbenv
[ruby-build]: https://github.com/rbenv/ruby-build
[ruby-install]: https://github.com/postmodern/ruby-install/

### BOSH cli
The Ruby version of the [BOSH cli] is required as of writing, as fissile is not
yet compatible with the golang BOSH v2.

[BOSH cli]: https://rubygems.org/gems/bosh_cli

### certstrap
Required to create certificates. Requires golang.
```sh
go get github.com/square/certstrap
```

## Building

1. Run `generate-certs.sh` to generate the SSL certificates required.  The
    default options are fine.
2. Create the BOSH release for `cf-mysql`, `uaa`, and `hcf`:
    ```
    bosh create release --dir src/cf-mysql-release --force --name cf-mysql
    bosh create release --dir src/uaa-release --force --name uaa
    bosh create release --dir src/hcf-release --force --name hcf
    ```
3. Build fissile images
    ```
    fissile build layer compilation
    fissile build layer stemcell
    fissile build packages
    fissile build images
    ```

## Running

The default configurations are designed for the [hcf] vagrant box; see 
instructions there.

[hcf]: https://github.com/hpcloud/hcf

1. If necessary, push the images to your Kubernetes nodes (or publish them in a
    way that they get fetch the images).
2. Build Kubernetes configs. This will create the files in a directory named `kube`:
    ```
    fissile build kube -k kube/ --use-memory-limits=false \
        -D $(echo env/*.env | tr ' ' ',')
    ```
    If you are not building the images directly on the Kubernetes cluster (or if
    you have multiple nodes), you will also need to specify
    `--docker-registry=docker.registry:123456` (and possibly
    `--docker-organization`) so that the images can be pulled.
3. Deploy to Kubernetes
    ```
    # The following is a sample for hyperkube/minikube/vagrant
    kubectl create -f kube-test/storage-class-host-path.yml

    kubectl create namespace uaa

    kubectl create -n uaa -f kube/bosh/

    # This will expose UAA for use; adjust the contents if you're not deploying
    # to vagrant
    kubectl create -n uaa -f kube-test/exposed-ports.yml
    ```
