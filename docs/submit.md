# submit.py

The submit script contains the logic for submitting a single job to the
local job scheduler, which can be HTCondor, PBS, SLURM, or others.

The config file supports limited customization of the generated submit files
to handle variations between sites running the same submit system.
