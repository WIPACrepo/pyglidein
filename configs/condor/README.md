# Automatically sized glideins in Condor

When running glideins on a heterogenous HTCondor pool, it can be useful to submit glideins that exactly match the available resources. These scripts do just that.

## Usage

`configs/condor/submit.sh [BASE_SUBMIT_FILE]`

`BASE_SUBMIT_FILE` should be a Condor submit file that contains everything needed to run the pilot, _except_ resource requests and a queue statement. If omitted, it defaults to configs/desy.condor.

This does the following:
1. Query `condor_status` for partitionable slots (GPU only at the moment), and group them by cpu count, gpu count, memory, and disk
2. For each group, assign a label based on the first hostname, and a size N
3. Ensure that N jobs are queued for each group, with resource requests filling the slot resources

When the jobs runs, `glidein_start.sh` exposes the relevant fields of the slot classad as environment variables so the pilot knows which resources it should advertise.

## Requirements

- HTCondor
- bash
- [jq](https://jqlang.github.io/jq/)

## Utilities

- groups.sh: groups partitionable slots by available resources
- jobs.sh: count queued jobs by attribute (by default, `pyglidein_partition`)
