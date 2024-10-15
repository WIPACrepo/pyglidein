#!/bin/bash

# Inventory machines exposed to UGE, emitting one JSON doc per line, e.g.
# {"host":"turing01.zeuthen.desy.de","cpus":32,"memory":376384,"disk":1438839,"gpus":8,"gpu_type":"nvidia_geforce_rtx_2080_ti"}
# Requires xq (https://pypi.org/project/xq/)

condor_status -const 'SlotType=="Partitionable"' --json | jq -c "$(cat <<"EOF"
def enumerate: foreach .[] as $value (-1; .+1; {key: .|tostring, value: $value});
def tonearest(base): ((.|tonumber)/base|floor)*base;
def group_label: .value[0].host | split(".")[0];
def tosize:
  (.[:-1] | tonumber)*(1e3);
map(
  select(.TotalGPUs > 0) |
  {
    host: .UtsnameNodename,
    cpus: .TotalCpus,
    memory: (.TotalSlotMemory) | tonearest(pow(2;10)),
    disk: (.TotalSlotDisk) | tonearest(pow(2;20)),
    gpus: .TotalGPUs,
    gpu_type: .GPUs_DeviceName
  }
)
# group by cores, mem/core, disk, and gpu count, with appropriate rounding
| group_by([.cpus, ((.memory/.cpus)|tonearest(pow(2;10))), .disk, .gpus])
| [ 
  enumerate
# take first doc in group, count entries, and add a label
  | (.value[0] | del(.host))+{label: . | group_label, count: .value|length}
  ] 
EOF
)"



