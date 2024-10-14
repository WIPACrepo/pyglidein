#!/bin/bash

# Inventory machines exposed to UGE, emitting one JSON doc per line, e.g.
# {"host":"turing01.zeuthen.desy.de","cpus":32,"memory":376384,"disk":1438839,"gpus":8,"gpu_type":"nvidia_geforce_rtx_2080_ti"}
# Requires xq (https://pypi.org/project/xq/)

condor_status -const 'SlotType=="Partitionable"' --json | jq -c "$(cat <<"EOF"
def tosize:
  (.[:-1] | tonumber)*(1e3);
  map(
  select(.TotalGPUs > 0) |
  {
    host: .UtsnameNodename,
    cpus: .TotalCpus,
    memory: (.TotalMemory),
    disk: (.TotalDisk / 1024),
    gpus: .TotalGPUs,
    gpu_type: .GPUs_DeviceName
  }) | .[]
EOF
)"



