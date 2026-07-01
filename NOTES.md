# A file for notes for using pyglidein2

## Container

We are using the default OSG container. It is available through the OSG Harbor instance at:

`docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release`

so the full apptainer command is

`apptainer pull docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release`

## cvmfsexec

For those sites that don't have CVMFS installed. 

As of July 1, an incomplete list:

NCSA Delta
Purdue Anvil
TACC Lonestar6
TACC Stampede3
TACC Vista - ARM - Grace-Hopper
TACC Horizon - ARM - Vera-Rubin

1. Check out cvmfsexec to a location that is accessible to the worker node. Ideally on the home dir cause the many small files will affect 

`git clone https://github.com/cvmfs/cvmfsexec.git`

2. Make a distribution

In the cvmfsexec dir you need to run 

`./makedist osg`

This will download the necessary CVMFS examples and "generate" the executable to run CVMFS in user space.

The distribution will be places in `<CVMFSEXEC_LOCATION>/dist`

3. Executing cvmfsexec

In the slurm script, you need to copy the cvmfsexec dir and the `glidein_start.sh` script to the local scratch directory for the job. In the example below it is the `LOCAL_DIR`. Now simply executing 

`${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh`

4. Optional, alien cache

Some sites do not have a HTTP proxy cache close by or accessible. The only site with that issue so far is NCSA. They have a ATLAS Tier2 close-by, but they don't like to share. ATLAS MWT2 also uses Varnish as their HTTP proxy. This is generally not an issue with CVMFS.

On Delta, we modified `<CVMFSEXEC_LOCATION>/dist/etc/cvmfs/default.local`

```
CVMFS_HTTP_PROXY="dt-login01.delta.ncsa.illinois.edu:3128;dt-login03.delta.ncsa.illinois.edu:3128;DIRECT"
CVMFS_PAC_URLS="http://grid-wpad/wpad.dat;http://wpad/wpad.dat;http://cernvm-wpad.fnal.gov/wpad.dat;http://cernvm-wpad.cern.ch/wpad.dat"
CVMFS_ALIEN_CACHE=/projects/bbfw/riedel1/cvmfs
CVMFS_QUOTA_LIMIT=-1
CVMFS_SHARED_CACHE=no 
```

The `CVMFS_ALIEN_CACHE` is the location on a shared disk (can be accessed by all workers) that a cache will be placed. The suggestion is to not place this on a distributed filesystem. The Delta `/projects` is a distributed filesystem (Lustre) and has not had issues with the cache. `CVMFS_ALIEN_CACHE` requires `CVMFS_QUOTA_LIMIT=-1` and `CVMFS_SHARED_CACHE=no`.

## Future Steps

* Brian Bockelman's REST Endpoint for the AP (https://github.com/bbockelm/golang-htcondor) as the source for the pyglidein submission mechanism. We have be running without querying the AP because SU calculation for GPU jobs does not necessarily include the CPU time in sensical way. Generally, something like 1 SU = 1 GPU hr + a fraction of the  CPU cores and RAM depending on how many GPUs are on the machine, i.e. if 8 GPU you get 1/8th of RAM and CPU cores. We would be "wasting" SU by not using resources we could be assigned. 
* ARM CVMFS release - HTCondor EP is now released on ARM as well. We don't an ARM-based cvmfs build at this point. arm-1 could be used to build these inside a container and then move the data to stratum-0. stickier issue is the jobs defaulting to requiring the microarch of the AP, i.e. grid-submitter adds a requirements for x86_64 by default. To use the ARM-based EP, we will need to submit through iceprod. Iceprod will need to check 1) is this a job that uses a cvmfs released icetray 2) alter the requirements of the job to include x86_64 or ARM



