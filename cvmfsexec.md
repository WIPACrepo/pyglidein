# cvmfsexec

some sites don't have CVMFS installed, so we have to spin up our own.
for that we use [cvmfsexec](https://github.com/cvmfs/cvmfsexec), a pile of bash scripts that allow you to deploy cvmfs in unprivileged user space. this requires that user namespaces are enabled. 

as of november 2026, the ACCESS sites that _do not_ have native CVMFS and require cvmfsexec are:
- NCSA Delta
- Purdue Anvil
- TACC Lonestar6
- TACC Stampede3
- TACC Vista (ARM - Grace-Hopper)
- TACC Horizon (ARM - Vera-Rubin)

## setup

1. clone

check out cvmfsexec to a location that is accessible to worker nodes. ideally on a non-distributed filesystem that can handle many small files without issues.

`git clone https://github.com/cvmfs/cvmfsexec.git`

from here on, we'll use `<CVMFSEXEC_LOCATION>` to refer to the location where you cloned this repo.

2. build

`./makedist osg` (in the repo you just cloned)

this will get everything set up and build the executable to run CVMFS in userspace. the distribution will be placed in `<CVMFSEXEC_LOCATION>/dist/`

3. run

in the slurm script, you need to copy the cvmfsexec dir alongside the `glidein_start.sh` script to the local scratch directory for the job. in the example below it is the `LOCAL_DIR`. 
then, instead of running `glidein_start.sh` directly at the end of your slurm script, you need to call it inside of the cvmfsexec environment like so:

`${LOCAL_DIR}/cvmfsexec/cvmfsexec config-osg.opensciencegrid.org oasis.opensciencegrid.org singularity.opensciencegrid.org icecube.opensciencegrid.org -- ./glidein_start.sh`

4. alien cache (optional)

some sites do not have a HTTP proxy cache close by or accessible. the only site with that issue so far is NCSA. they have a ATLAS Tier2 close-by, but they don't like to share. ATLAS MWT2 also uses Varnish as their HTTP proxy. this is generally not an issue with CVMFS.

on delta, we modified `<CVMFSEXEC_LOCATION>/dist/etc/cvmfs/default.local` to account for this:

```
CVMFS_HTTP_PROXY="dt-login01.delta.ncsa.illinois.edu:3128;dt-login03.delta.ncsa.illinois.edu:3128;DIRECT"
CVMFS_PAC_URLS="http://grid-wpad/wpad.dat;http://wpad/wpad.dat;http://cernvm-wpad.fnal.gov/wpad.dat;http://cernvm-wpad.cern.ch/wpad.dat"
CVMFS_ALIEN_CACHE=/projects/bbfw/ehobert/cvmfs
CVMFS_QUOTA_LIMIT=-1
CVMFS_SHARED_CACHE=no 
```

the `CVMFS_ALIEN_CACHE` is the location on a shared disk (can be accessed by all workers) that a cache will be placed. the suggestion is to not place this on a distributed filesystem. on delta, `/projects` is a distributed filesystem (Lustre) and has not had issues with the cache. `CVMFS_ALIEN_CACHE` requires `CVMFS_QUOTA_LIMIT=-1` and `CVMFS_SHARED_CACHE=no`.

note on TACC: you will need to test everything in a interactive slot and not on the submit/login host. The submit/login nodes are significantly locked down compared to an interactive slot.
