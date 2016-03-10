pyglidein
=========

A python server-client pair for submitting HTCondor glidein jobs on
remote batch systems.

Overview
--------

![graphical overview](docs/overview.png)

As pictured above, pyglidein is used to run glideins on remote sites,
adjusting for pool demand automatically. It consists of a server
running on the central HTCondor submit machine and a number of clients
on remote submit machines. The client will submit glideins which
connect back to the central HTCondor machine and advertise slots
for jobs to run in. Jobs then run as normal.

Install
-------

To install, just `git clone` the repository to a local directory. These
are just scripts, so they can be used directly.

### Server

Running the server is fairly simple:

    $ ./server.py -p PORT_NUMBER

This will start the server with default options, with the server listening
on the specified port for requests from the client.

Once you're satisfied that the server is working, running it with `nohup`
is best.

### Client

The client can be set up in a number of ways, but simple execution is:

    $ ./client.py --config=CLUSTER_CONFIG_FILE

All settings are stored in the config file. The important settings are:

    [Glidein]
    # full server url to jsonrpc
    address = SERVER_URL

    [Cluster]
    # scheduler types (htcondor, pbs, slurm, ...)
    scheduler = htcondor

    # cmd to submit a job
    submit_command = condor_submit

    # cmd to determine how many jobs are on the cluster
    running_cmd = condor_q|wc -l

    # queue limits
    max_total_jobs = 1000
    limit_per_submit = 50

This is routinely run in a `cron`, but can also be run continuously with:

    [Glidein]
    # run every 60 seconds
    delay = 60

Documentation
-------------

Detailed documentation is available [here](docs/index.md).