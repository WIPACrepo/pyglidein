# Client

The client is broken up into several parts, with the driving logic in
`client.py`.

## client.py

The main script for the client handles interaction with the server and
decides which idle jobs could be matched by the remote site. It then
attempts to submit up to a rate limit and max jobs (idle/running) limit.

## submit.py

The submit script contains the logic for submitting a single job to the
local job scheduler, which can be HTCondor, PBS, SLURM, or others.

The config file supports limited customization of the generated submit files
to handle variations between sites running the same submit system.

## Glidein startup

Glideins start via a shell script, which sets some environment variables
to configure HTCondor to run appropriately.

* [glidein_start.sh](glidein_start.md)

## Example configs

* [HTCondor](cluster_htcondor_example.config)
* [PBS](cluster_pbs_example.config)
