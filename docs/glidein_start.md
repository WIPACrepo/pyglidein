# glidein_start.sh

The glidein wrapper contains the more easily modifiable condor variables
for fast testing/tuning. It will download the glidein tarball if necessary,
untar it, and start a condor startd with an appropriate environment.

The startd is configured for dynamic, partitionable slots, allowing it to
be repartitioned while running if job requirements change over the lifetime
of the glidein.

After a set amount of wall time, the glidein will signal the startd to
begin graceful shutdown. The retirement grace limit gives jobs a short time
to complete and won't start any new jobs. Idle glideins have an activity
timeout after which they die.

## Environment Variables

The following variables can be set to configure things:

* SITE - Name of the client site.

* CLUSTER - Address of the HTCondor master instance.

* WALLTIME - Time in seconds during which the glidein accepts new jobs.
  Default is 14 hours.

* RETIRETIME - Time in seconds that the glidein will wait for a job to
  exit before killing it. Default is 20 minutes.

* NOCLAIMTIME - Time in seconds that the glidein will sit idle (no jobs
  running) before it kills itself. Default is 10 minutes.

* CPUS - Number of CPUs the glidein has access to. Default is 1.

* GPUS - GPUs the glidein has access to. Default is none.

* MEMORY - MEMORY in MB the glidein has access to. Default is 4 GB.

* DISK - DISK in KB the glidein has access to. Default is 8 GB.

* GLIDEIN_DIR - Directory containing `glidein.tar.gz`, if already available.
  Default is none, downloading from
  http://prod-exe.icecube.wisc.edu/glidein.tar.gz
