# glidein_start.sh

The glidein wrapper contains the more easily modifiable condor variables
for fast testing/tuning. It will download the glidein tarball if necessary,
untar it, and start a condor startd with an appropriate environment.

The startd is configured for dynamic, partitionable slots, allowing it to
be repartitioned while running if job requirements change over the lifetime
of the glidein.

After a set amount of time (default 14 hours), the glidein will signal
the startd to begin graceful shutdown. The grace limit (default 20 minutes)
gives jobs a short time to complete and won't start any new jobs. Idle
glideins have an activity timeout (default 10 minutes) after which they die.
