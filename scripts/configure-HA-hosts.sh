#!/bin/bash

# This script sets up the various HA host address lists.  It is sourced during
# the startup script (run.sh), and we should avoid mutating global state as much
# as possible.

# Note: While every role has a metron-agent, and the metron-agent
# needs access to the etcd cluster, this does not mean that all roles
# have to compute the cluster ips. The metron-agent uses ETCD_HOST as
# its target, which the low-level network setup of the system
# round-robins to all the machines in the etcd sub-cluster.

find_cluster_ha_hosts() {
    local component_name="${1}"
    if test -z "${KUBERNETES_SERVICE_HOST:-}" ; then
        # on Vagrant / AWS ; HA is not supported
        # Fall back to simple hostname
        echo "[\"${component_name}\"]"
        return 0
    fi

    local hosts=''
    if test -z "${KUBERNETES_NAMESPACE:-}" ; then
        local i=0

        while test "${i}" -lt 100 ; do
            local varname="${component_name^^}_${i}_INT_SERVICE_HOST"
            # !varname => Double deref of the variable.
            if test -z "${!varname:-}" ; then
                break
            fi

            # Note: The varname deref gives us an IP address. We want the
            # actual host name, and construct it.
            hosts="${hosts},\"${component_name}-${i}.${HCP_SERVICE_DOMAIN_SUFFIX}\""
            i="$(expr "${i}" + 1)"
        done
    else
        # This is running on raw Kubernetes

        local this_component="${HOSTNAME%-*}"
        if test "${this_component}" != "${component_name}" ; then
            # When talking to other components, use the generic service hostname
            echo "[\"${component_name}\"]"
            return 0
        fi

        # Loop over the environment to locate the component name variables.
        local names=()
        local i
        for (( i = 0 ; i < 60 ; i ++ )) ; do
            names=($(dig "${component_name}.${HCP_SERVICE_DOMAIN_SUFFIX}" -t SRV | awk '/IN[\t ]+A/ { print $1 }'))
            if test "${#names[@]}" -gt 0 ; then
                break
            fi
            sleep 1
        done
        if test "${#names[@]}" -lt 1 ; then
            echo "No servers found for ${component_name}.${HCP_SERVICE_DOMAIN_SUFFIX} after 60 seconds; should at least have this container" >&2
            exit 1
        fi
        local name
        for name in "${names[@]}" ; do
            hosts="${hosts},\"${name%.}\""
        done
    fi

    # Return the result, with [] around the hostnames, removing the leading comma
    echo "[${hosts#,}]"
}

if test -n "${KUBERNETES_NAMESPACE:-}" ; then
    # We're on raw Kubernetes; install some compat things
    export HCP_IDENTITY_SCHEME=https
    export HCP_IDENTITY_EXTERNAL_HOST="uaa.${DOMAIN}"
    export HCP_IDENTITY_EXTERNAL_PORT=443
    # We don't have the cluster name directly available, but it's in resolv.conf, so grab it from there
    export HCP_SERVICE_DOMAIN_SUFFIX="$(awk '/^search/ { print $2 }' /etc/resolv.conf)"
fi

export CONSUL_HCF_CLUSTER_IPS="$(find_cluster_ha_hosts consul)"
export NATS_HCF_CLUSTER_IPS="$(find_cluster_ha_hosts nats)"
export ETCD_HCF_CLUSTER_IPS="$(find_cluster_ha_hosts etcd)"
export MYSQL_HCF_CLUSTER_IPS="$(find_cluster_ha_hosts mysql)"

unset find_cluster_ha_hosts
