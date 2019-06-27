# glidein_start_singularity.sh

This script is used to run the glidein in a singularity container. If
you plan to use this, be warned that it hasn't been tested on all sites. To use, change the executable line in the config file under [SubmitFile]
to point to this script. Then, execute the glidein client (an example
can be found at pyglidein/run.sh).

First, it runs a python script to parse out environment variables manually
and feed them into the container (this is a workaround for older singularity
versions that had a bug in passing environment variables through).

Then, it performs a number of checks for what resources are available
to be bind-mounted. It also checks if there is a local image to use for
the container, otherwise it will download it from dockerhub. Finally, it
checks if the SINGULARITY_BIN variable has been set (the absolute path
to a version of singularity). If no custom path has been set, it defaults
to assuming singularity is available on the PATH.

The container is finally run, executing glidein_start.sh with the given
image and given variables.

The variables that can be configured are:

* SINGULARITY_BIN - Absolute path to singularity executable
* ARGS - List of bindings to perform when creating the container
* CONTAINER - Absolute path to the image to utilize, or dockerhub path