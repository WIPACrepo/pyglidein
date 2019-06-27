pyglidein
=========

Contents
--------

* [server](server.md)
* [client](client.md)
  * [Configuration Index](configuration_index.md)
  * [Secrets Index](secrets_index.md)
  * [glidein_start_singularity](glidein_start_singularity.md)
  * [glidein_start](glidein_start.md)
  * [Startd Logging](startd_logging.md)
  * [Startd Monitoring](startd_monitoring.md)
  * [submit](client.md#submitpy)
* [create_glidein_tarball](create_glidein_tarball.md)
* [Python Packaging](packaging.md)
* [ssh_helper](ssh_helper.md)

Overview
--------

pyglidein is used to run glideins on remote sites,
adjusting for pool demand automatically. It consists of a server
running on the central HTCondor submit machine and a number of clients
on remote submit machines. The client will submit glideins which
connect back to the central HTCondor machine and advertise slots
for jobs to run in. Jobs then run as normal.

![graphical overview](overview.png)
