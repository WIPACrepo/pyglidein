pyglidein
=========

Contents
--------

* [server](server.md)
* [client](client.md)
  * [glidein_start](glidein_start.md)
  * [Startd Logging](startd_logging.md)
  * [submit](client.md#submitpy)
* [ssh_helper](ssh_helper.md)
* [create_glidein_tarball](create_glidein_tarball.md)

Overview
--------

pyglidein is used to run glideins on remote sites,
adjusting for pool demand automatically. It consists of a server
running on the central HTCondor submit machine and a number of clients
on remote submit machines. The client will submit glideins which
connect back to the central HTCondor machine and advertise slots
for jobs to run in. Jobs then run as normal.

![graphical overview](overview.png)
