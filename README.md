
Table of Contents
=================

   * [UAA fissile release](#uaa-fissile-release)
      * [Prerequisites](#prerequisites)
      * [Building](#building)
      * [Running](#running)
   * [Development FAQ](#development-faq)
      * [How do I bump the submodules for the various releases?](#how-do-i-bump-the-submodules-for-the-various-releases)

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
    ```

# Development FAQ

### How do I bump the submodules for the various releases?

__Note:__ Because this process involves cloning and building a release, it may take a long time.

__Note:__ This description assumes operation from within the SCF release.

This section describes how to bump all the submodules at the same
time. This is the easiest way because we have scripts helping us
here.

1. On the host machine run

    ```bash
       bin/update-releases.sh
    ```

    This pulls the CF release information from the enclosing SCF
    release. It is assumed that this SCF is bumped itself, and has a
    `_work` directory holding the bump state.  When doing this outside
    of an SCF release use

    ```bash
       bin/update-releases.sh /path/to/scf
    ```

    instead to specify which SCF release to use as the source of the version
    information.

    It places the version information it used in a subdirectory `_work`.

    `ATTENTION`: The script may mention submodules it has no
    information about, making manual matching of versions to commit
    the order of the day. Where possible the script will have created
    at least a clone of the release to start from.

1. Next up, we need the BOSH releases for the cloned and bumped submodules. Run

    ```bash
    bin/create-clone-releases.sh
    ```

    This command will place the log output for the individual releases
    into the sub directory `_work/LOG/ccr`.

1. With this done we can now compare the BOSH releases of originals
   and clones, telling us what properties have changed (added,
   removed, changed descriptions and values, ...).

    On the host machine run

    ```bash
    bin/diff-releases.sh
    ```

    This command will place the log output and differences for the
    individual releases into the sub directory `_work/LOG/dr`.

1. Act on configuration changes:

    __Important:__ If you are not sure how to treat a configuration
    setting, discuss it with the SCF team.

    For any configuration changes discovered in step the previous
    step, you can do one of the following:

    * Keep the defaults in the new specification.
    * Add an opinion (static defaults) to `./container-host-files/etc/scf/config/opinions.yml`.
    * Add a template and an exposed environment variable to `./container-host-files/etc/scf/config/role-manifest.yml`.

    Define any secrets in the dark opinions file `./container-host-files/etc/scf/config/dark-opinions.yml` and expose them as environment variables.

1. Evaluate role changes:

    1. Consult the release notes of the new version of the release.
    1. If there are any role changes, discuss them with the SCF team, [follow steps 3 and 4 from this guide](#how-do-i-add-a-new-bosh-release-to-scf).

1. Bump the real submodule:

    1. Bump the real submodule and begin testing.
    1. Remove the clone you used for the release.

1. Test the release by running the `make <release-name>-release compile images run` command.

   Alternatively move to the enclosing SCF release and test from
   there, as part of the whole system.
