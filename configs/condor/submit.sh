#!/bin/bash

# Group available machines by cpus/gpus/memory/disk, and ensure that N whole-machine glideins are queued for each group

set -eo pipefail

submit_file=${1:-$DIR/../desy.condor}
DIR=$( dirname -- "${BASH_SOURCE[0]}" )

jq -r "$(cat <<"EOF"
# pass on groups with more members than queued jobs
map((.submit=(.count - ($jobs[.label] // 0))| select(.submit>0)))[]
# construct condor_submit options
| "-a request_cpus=\(.cpus) -a request_memory=\(.memory) -a request_disk=\(.disk) -a request_gpus=\(.gpus) -a +pyglidein_partition=\\\"\(.label)\\\" -queue \(.submit)"
EOF
)" <($DIR/groups.sh) \
--argjson jobs "$(./configs/jobs.sh)" \
| xargs --no-run-if-empty --verbose -L1 condor_submit $submit_file

