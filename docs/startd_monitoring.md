# Startd Monitoring

HTCondor provides a `CRON` service for running periodic jobs on the `startd`.  Output from these jobs are treated as Classad expressions and are injected into the startd Classad list.  This service is useful for running functionality tests on remote compute nodes.  The Classads that are injected by the tests can then be used at job submission time to ensure necessary requirements are being met.  

## Pre and Post CVMFS scripts

pyGlidein provides a Pre and Post CVMFS wrapper script for running Startd CRON jobs with and without CVMFS access.  Set `STARTD_CRON_EXECUTABLE=../../pre_cvmfs.sh` to use the pre CVMFS wrapper and set the `STARTD_CRON_EXECUTABLE=../../post_cvmfs.sh` to use the post CVMFS wrapper script.  

## Accessing Scripts

HTCondor's working directory is inside the log directory, which is two directories below the location of transfered Startd Monitoring scripts.  When referencing Startd Monitoring scripts in the HTCondor configuration always preface the script name with `../../`.

## Classad Structure (Resources and Metrics)

pyGlidein Startd CRON scripts create two types of Classad expressions.  Classads that begin with `PYGLIDEIN_RESOURCE_` describe the availability of a resource.  They should always be set to `True` or `False`.  Classads that begin with `PYGLIDEIN_METRIC_` provide a measurement of performance of a resource.

## pyGlidein Provided scripts

pyGlidein provides a set of predefined Startd CRON scripts for testing resource availability on remote compute nodes

### clsim_gpu_test.py

Runs the `CLSIM` benchmark to ensure the availability of a GPU resource and provides photon metrics measured in NS for the GPU.

* PRE/POST CVMFS: Post
* Resource Classads: PYGLIDEIN_RESOURCE_GPU
* Metrics Classads: PYGLIDEIN_METRIC_TIME_PER_PHOTON

### cvmfs_test.py

Runs an md5sum operation on a file inside CVMFS to ensure CVMFS availability.

* PRE/POST CVMFS: Pre
* Resource Classads: PYGLIDEIN_RESOURCE_CVMFS

### gridftp_test.py

Uses telnet to access the control port of a gridftp server.  The output is checked for `220`, `GridFTP Server`, and `ready`.

* PRE/POST CVMFS: Post
* Resource Classads: PYGLIDEIN_RESOURCE_GRIDFTP
