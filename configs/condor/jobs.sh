#!/bin/bash

# Count condor jobs grouped by attribute

classad=${1:-pyglidein_partition}

condor_q -json -af $classad | jq -seRc 'if . == "" then [] else fromjson end | map(select(.'$classad')) | group_by(.'$classad') | map({key: .[0].'$classad', value: .|length}) | from_entries'

