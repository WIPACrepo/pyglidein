#!/bin/bash
set -e

# This assume we are on a RHEL style system

# install some packages
echo "Installing HTCondor and friends"
sudo dnf install -y wget nano
sudo dnf install -y https://repo.osg-htc.org/osg/25-main/osg-25-main-el9-release-latest.rpm
sudo dnf install -y https://htcss-downloads.chtc.wisc.edu/repo/25.x/htcondor-release-current.el9.noarch.rpm
sudo dnf update -y
sudo dnf install -y osg-oasis condor

# CVMFS config
echo "Now writing config files"
sudo tee /etc/cvmfs/default.local > /dev/null << 'EOF'
CVMFS_REPOSITORIES="oasis.opensciencegrid.org,icecube.opensciencegrid.org,singularity.opensciencegrid.org"
CVMFS_QUOTA_LIMIT=50000
CVMFS_HTTP_PROXY="direct"
EOF
sudo tee /etc/auto.master.d/cvmfs.autofs > /dev/null << 'EOF'
/cvmfs /etc/auto.cvmfs
EOF
sudo systemctl enable autofs
sudo systemctl start autofs

# HTCondor config
sudo tee /usr/local/bin/cvmfs_check.sh > /dev/null << 'EOF'
#!/usr/bin/env bash
# /usr/local/bin/cvmfs_check.sh
# Dynamically discovers CVMFS repos and reports status + xattr stats to HTCondor.

TIMEOUT=5
declare -A REPOS

# 1. Parse configured repositories from /etc/cvmfs/default.local
if [[ -f /etc/cvmfs/default.local ]]; then
    config_repos=$(grep -E '^\s*CVMFS_REPOSITORIES=' /etc/cvmfs/default.local \
                   | cut -d'=' -f2- \
                   | tr -d '"' \
                   | tr -d "'" \
                   | tr ',' ' ')
    for repo in $config_repos; do
        REPOS["$repo"]=1
    done
fi

# 2. Check for dynamic/active mounts via cvmfs_config
if command -v cvmfs_config &>/dev/null; then
    while read -r repo _; do
        if [[ -n "$repo" ]]; then
            REPOS["$repo"]=1
        fi
    done < <(cvmfs_config status 2>/dev/null | awk '{print $1}')
else
    if [[ -d /cvmfs ]]; then
        while read -r repo_path; do
            repo_name=$(basename "$repo_path")
            if [[ "$repo_name" != "*" && -n "$repo_name" ]]; then
                REPOS["$repo_name"]=1
            fi
        done < <(find /cvmfs -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    fi
fi

# Helper function to query CVMFS extended attributes
get_xattr() {
    local attr_name="$1"
    local path="$2"

    if command -v attr &>/dev/null; then
        attr -q -g "$attr_name" "$path" 2>/dev/null
    elif command -v getfattr &>/dev/null; then
        getfattr -n "user.$attr_name" --only-values "$path" 2>/dev/null
    else
        echo ""
    fi
}

# 3. Probe each discovered repo and print ClassAd key-value pairs
for repo in "${!REPOS[@]}"; do
    clean_repo_name=$(echo "$repo" | tr '.-' '__')
    path="/cvmfs/${repo}"

    # Verify directory accessibility
    if timeout "$TIMEOUT" ls "$path" >/dev/null 2>&1; then
        echo "HAS_CVMFS_${clean_repo_name} = True"

        # Extract CVMFS xattrs (revision, number of I/O errors, last I/O error timestamp)
        revision=$(get_xattr "revision" "$path")
        nioerr=$(get_xattr "nioerr" "$path")
        last_ioerr=$(get_xattr "last_ioerr" "$path")

        # Fallbacks/Defaults if xattr returns empty
        [[ -z "$revision" ]] && revision=0
        [[ -z "$nioerr" ]] && nioerr=0
        [[ -z "$last_ioerr" ]] && last_ioerr=-1

        echo "CVMFS_${clean_repo_name}_REVISION = ${revision}"
        echo "CVMFS_${clean_repo_name}_NIOERR = ${nioerr}"
        echo "CVMFS_${clean_repo_name}_LAST_IOERR = ${last_ioerr}"
    else
        echo "HAS_CVMFS_${clean_repo_name} = False"
        echo "CVMFS_${clean_repo_name}_REVISION = 0"
        echo "CVMFS_${clean_repo_name}_NIOERR = -1"
        echo "CVMFS_${clean_repo_name}_LAST_IOERR = -1"
    fi
done

echo "- update:true"

exit 0
EOF
sudo chmod +x /usr/local/bin/cvmfs_check.sh
sudo tee /etc/condor/config.d/20-custom > /dev/null << 'EOF'
# ------------------------------------------------------------------------------
# 1. System Role & Central Manager Connection
# ------------------------------------------------------------------------------
# Meta-knob to configure this node strictly as an execution point
use role: Execute

# Your Central Manager hostname or IP
CONDOR_HOST = glidein-cm.icecube.wisc.edu

# ------------------------------------------------------------------------------
# 2. Network & Firewall Traversal (CCB)
# ------------------------------------------------------------------------------
# Enables Condor Connection Broker so the Central Manager can reach this node
# through NAT/Firewalls without requiring inbound open ports on this machine.
CCB_ADDRESS = $(CONDOR_HOST)

# ------------------------------------------------------------------------------
# 3. Security & Authentication
# ------------------------------------------------------------------------------
# Meta-knob enabling standard security defaults (token authentication, encryption)
#use security: Recommended

# Path to the IDTOKEN supplied by the Central Manager
SEC_TOKEN_DIRECTORY = /etc/condor/tokens.d

# ------------------------------------------------------------------------------
# 4. Resource Allocation & Isolation (cgroups v2)
# ------------------------------------------------------------------------------
# Enables modern Partitionable Slots (dynamic carving of CPU/RAM per job)
use feature: PartitionableSlot
use policy: Always_Run_Jobs
use policy: Startd_Publish_CpusUsage

# Enables cgroups v2 tracking and isolation for memory, CPU, and swap
#use feature: cgroups

# ------------------------------------------------------------------------------
# 5. Policy: Run to Completion & Delegate Enforcement
# ------------------------------------------------------------------------------
# Disable local preemption, suspension, and eviction on the execution point
#PREEMPT = False
#WANT_SUSPEND = False
#WANT_VACATE = False

# Do not kill or hold jobs locally when soft limits are exceeded;
# let cgroups track usage and allow the submit node (schedd) to enforce policies.
CGROUP_MEMORY_LIMIT_POLICY = none

# ------------------------------------------------------------------------------
# 6. Custom attrs
# ------------------------------------------------------------------------------
START_EXTRA = (TARGET.IceProdSite =?= "long" || TARGET.Owner =?= "ice3simusr" && regexp("Long",TARGET.JobDurationCategory))

GLIDEIN_Country = "US"
GLIDEIN_ResourceName = "IU Jetstream 2"
GLIDEIN_Site = "IU Jetstream 2"
GLIDEIN_ToRetire = 100000000000

STARTD_ATTRS = $(STARTD_ATTRS) START_EXTRA GLIDEIN_Country GLIDEIN_Site GLIDEIN_ResourceName GLIDEIN_ToRetire

START = $(START) && (START_EXTRA ?: true)

RANK = ifThenElse(TARGET.IceProdSite =?= "long", 100, 0)


# ------------------------------------------------------------------------------
# 7. Singularity config
# ------------------------------------------------------------------------------
SINGULARITY_JOB = !isUndefined(TARGET.SingularityImage)
SINGULARITY_IMAGE_EXPR = TARGET.SingularityImage
SINGULARITY_BIND_EXPR = "/cvmfs"
EOF
sudo tee /etc/condor/config.d/51-cvmfs-cron.conf > /dev/null << 'EOF'
# ------------------------------------------------------------------------------
# Startd Cron: Dynamic CVMFS Health & Extended Metrics Check
# ------------------------------------------------------------------------------

STARTD_CRON_AUTOPUBLISH = If_Changed
STARTD_CRON_JOBLIST = $(STARTD_CRON_JOBLIST) CVMFS
SCHEDD_CRON_LOG_NON_ZERO_EXIT = True

STARTD_CRON_CVMFS_EXECUTABLE = /usr/local/bin/cvmfs_check.sh
STARTD_CRON_CVMFS_PERIOD = 1m
STARTD_CRON_CVMFS_MODE = Periodic
STARTD_CRON_CVMFS_KILL = True
STARTD_CRON_CVMFS_RECONFIG_RERUN = True

# Automatically import attributes beginning with HAS_CVMFS_ or CVMFS_
STARTD_ATTRS = $(STARTD_ATTRS) HAS_CVMFS_* CVMFS_*
EOF
sudo tee /etc/condor/config.d/99-logging > /dev/null << 'EOF'
#STARTD_DEBUG = D_FULLDEBUG
EOF

# Check for NVIDIA GPU using lspci (PCI vendor ID 10de indicates NVIDIA)
if lspci -d 10de: -nn | grep -q -i "VGA\|3D"; then
    echo "NVIDIA GPU detected. Proceeding with driver and CUDA installation..."
    sudo dnf install -y almalinux-release-nvidia-driver
    sudo dnf update -y
    sudo dnf install -y cudnn9-cuda-12-8 nvidia-driver-cuda

    sudo tee /etc/condor/config.d/22-gpus > /dev/null << 'EOF'
###
# Enable GPUs
###

use feature: GPUs
use feature: GPUsMonitor

RoomForCPUOnlyJobs = (GPUs =?= undefined) || (GPUs == 0) || ((SlotType == "Partitionable") && (CPUs > 8 * GPUs) && (Memory > 32000 * GPUs) && (Disk > 5000000 * GPUs))
START_EXTRA = $(START_EXTRA) && ((MY.GPUs ?: 0) == 0 || (TARGET.RequestGPUs ?: 0) > 0 || RoomForCPUOnlyJobs =?= undefined || RoomForCPUOnlyJobs)
STARTD_ATTRS = $(STARTD_ATTRS) RoomForCPUOnlyJobs
EOF

    echo "CUDA installed. A reboot will be required."
fi

# HTCondor token
echo "Please write the glidein token into /etc/condor/tokens.d/token"
sudo touch /etc/condor/tokens.d/token
sudo chmod 600 /etc/condor/tokens.d/token

sudo systemctl enable condor
