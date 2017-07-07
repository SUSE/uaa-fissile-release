# UAA fissile release

This repository contains the files necessary to run a standalone UAA using fissile.
It is roughly equivalent to doing the same with BOSH.

## Prerequisites

### A Kubernetes cluster

[scf.git] has sample instructions for setting one up locally via hyperkube;
other methods of deploying Kubernetes should work as well.

[scf.git]: https://github.com/suse/scf/tree/master/docs/kube.md

### docker
Docker is required for [fissile] to build images.  You may also need access to a
[docker registry] unless you're testing against a vagrant box or [minikube].  In
the case of [minikube], reusing the [minikube docker daemon] may be useful.

[docker registry]: https://github.com/docker/distribution
[minikube]: https://kubernetes.io/docs/getting-started-guides/minikube/
[minikube docker daemon]: https://kubernetes.io/docs/getting-started-guides/minikube/#reusing-the-docker-daemon

### fissile

[fissile] is required to build the docker images and configuration.

[fissile]: https://github.com/suse/fissile

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

### stampy

Used to write timing information to a file. This information can be used to identify
slow parts of the process when trying to make things faster.

Requires golang.
```sh
go get -d github.com/SUSE/stampy
cd $GOPATH/src/github.com/SUSE/stampy
make
cp build/linux-amd64/stampy $GOBIN/stampy
```

## Building

1. Get all submodules:
  ```sh
    git submodule update --init --recursive
  ```

1. Load needed environment variables (optional, only if you don't use direnv):

   ```sh
     . .envrc
   ```

1. Generate the SSL certificates required:

    ```sh
      make certs
    ```

1. Create the releases:

   ```sh
     make releases
   ```

1. Get the opensuse stemcell:

   ```sh
     docker pull $FISSILE_STEMCELL
   ```

1. Create a directory to write the release tarball into:

   ```sh
     mkdir -p output/splatform
   ```

1. Build fissile images:

   ```sh
   STEMCELL=splatform/fissile-stemcell-opensuse:42.2-0.g58a22c9-28.16
   fissile build packages --stemcell ${STEMCELL}
   fissile build images   --stemcell ${STEMCELL}
   ```

Or, more convenient

    ```sh
    make images
    ```

Note, the specified stemcell is an example. Change it to suit.  The
alternative command uses the definition of `FISSILE_STEMCELL` in
`.envrc` for this.

## Running

The default configurations are designed for the [scf] vagrant box; see
instructions there.

[scf]: https://github.com/suse/scf

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
3. If you're not building directly on a single Kubernetes node that you will
   deploy to, you will need to publish to the specified docker registry:
   ```sh
   fissile show image | xargs -i@ docker tag @ "${FISSILE_DOCKER_REGISTRY}/@"
   fissile show image | xargs -i@ docker push "${FISSILE_DOCKER_REGISTRY}/@"
   ```
4. Deploy to Kubernetes
    ```sh
    # The following is a sample for hyperkube/minikube/vagrant
    kubectl create -f kube-test/storage-class-host-path.yml

    kubectl create namespace uaa

    kubectl create -n uaa -f kube/bosh/

    # This will expose UAA for use; adjust the contents if you're not deploying
    # to vagrant
    kubectl create -n uaa -f kube-test/exposed-ports.yml
    ```
