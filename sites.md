# sites

notes and context about sites go here.  
however this is not intended as a source of truth, always refer to the site docs and the live configs if you need to be sure!


## fleet

| site | gpus used | walltime | submit | mfa | cvmfs |
| --- | --- | --- | --- | --- | --- |
| NCSA Delta | A40 | 48h | manual | password + duo push | cvmfsexec |
| Purdue Anvil | A100 | 24h | manual | ssh key | cvmfsexec |
| Harvard | varies | 48h | scrontab | password + totp | native |
| Fir | H100 (mig slices) | 72h | manual | password + totp | native |
| NERSC Perlmutter | A100 | 24h | scrontab | sshproxy cert (24h) | native |
| TACC Stampede3 | H100 | 48h | crontab | ssh key + totp | cvmfsexec |

not all sites support (s)crontab and some have to be submitted manually every so often. given our large array sizes this only has to happen every few weeks usually, but it varies between clusters. for Anvil (and maybe Fir through their robot node?) we may be able to set up an external cronjob in our kubernetes cluster that SSHes in and runs the submit script, but this is yet to be done. unless something changes Delta will always be manual, since they require duo push for SSH.

### NCSA Delta

docs: <https://docs.ncsa.illinois.edu/systems/delta/en/latest/>  
login: `login.delta.ncsa.illinois.edu` (password + duo push)

- no cron and no unattended ssh, so there is nothing to automate. though we can submit large arrays which easily last for weeks.
- delta has NVIDIA H200, A100, A40 and AMD MI100. for photon prop, A40s are ideal. A40s are the same speed as A100s for photon prop and have a 50% discount on usage compared to A100s. H200s are about 2x A40s, but we are looking for throughput so more slower resources are better.
- one gpu per task always lands on `GPU0`, the job runs in a cgroup.
- cvmfsexec needs the alien cache or the FNAL stratum-1 gets unhappy. so we do some surgery to make it work, see [cvmfsexec.md](cvmfsexec.md).

### Purdue Anvil

docs: <https://docs.rcac.purdue.edu/userguides/anvil/>  
login: `anvil.rcac.purdue.edu` (ssh key)

- no cron and no scrontab, but plain non-interactive ssh works, so in theory we could set up a remote cronjob.
- you will need to use their OpenOnDemand interface to add your SSH key to the login node before you can ssh in normally.
- 12 gpus in use per user and 32 per allocation, so one person cannot fill the gpu allocation alone.

### Harvard

docs: <https://docs.rc.fas.harvard.edu>  
login: `login.rc.fas.harvard.edu` (password + totp)

- scrontab is supported.
- both cpu and gpu jobs run on pre-emptible queues. this gives us a lot of capacity since we essentially get to scavenge their unused cycles, but it does mean jobs here can get terminated at any point. in practice though this doesn't seem to happen too often to cause problems. our glideins will just restart when a new slot opens up and condor will automatically requeue any terminated jobs and all is well.
- because we run on the pre-emptible queue we may get any of their gpus, including mig slices, so we need to pass along a `GPUs_Capability` level to make those work properly.
- the allocation runs through the lab, not ACCESS.

### Fir

docs: <https://docs.alliancecan.ca/wiki/Fir>  
login: `fir.alliancecan.ca` (password + totp)

- like harvard, mig slices do not get a `GPUs_Capability` classad, so we set it by hand. 
- the docs say crontab is not supported, but there is a so-called 'automation node' that may allow us to set up remote cronjobs, though this is yet to be fully explored.
- there's a handful of unused alternate configs in `configs/`. fir has a lot of flexibility in both max walltime and hardware configurations. though given how their cluster is segmented based on walltime maxing it out to the full 7 days would severely limit how much resources we'd have access to. 3 days is a good balance. mig slices are also generally preferred over whole gpus since we don't need a full h100. the smallest slices come with too few cores for us to use effectively.

### NERSC Perlmutter

docs: <https://docs.nersc.gov>  
login: `perlmutter.nersc.gov` (password + otp once, then a 24h sshproxy cert)

- for nersc we use the shared `icecubed` account rather than personal accounts. it also uses `sshproxy` to generate temporary certs for logging in over ssh. 
- the allocation is small, so the array is small and rate limited on purpose to make sure we don't blow through it all at once.

### TACC Stampede3

docs: <https://docs.tacc.utexas.edu/hpc/stampede3/>  
login: `login2.stampede3.tacc.utexas.edu` (ssh key + totp, cron pinned to this node as of august 2026)

- cron, not scrontab, and crontabs are per login node. we pinned `login2` so we do not end up with multiple conflicting cronjobs.
- no node sharing, whole nodes only.
- the `h100` partition allows only 2 running and 4 submitted jobs per user, so the helper tops up to four instead of waiting for the queue to drain.

### JetStream2

jetstream is unique in our fleet. it's an openstack cluster rather than a cluster running slurm. you get VMs that run "forever". this is perfect for long-running jobs, though this comes at the cost of having to setup the VM. to best utilize this capacity we've got jetstream configured with its own full condor install rather than glideins. see `helpers/setup_jetstream2.sh` for details.

## potential sites

Utah has three clusters that we could use, BUT your account will be suspended every 6 months. if you want to do it, the configs are ready.

SDSC's Cosmos is a new cluster with AMD MI300X. recent condor releases fixed the AMD GPU discovery that limited their use before. it mostly requires testing.

Intel Ponte Vecchio gpus on stampede3 are available. historically underutilized they should work, but there are two wrinkles: opencl device detection in condor and having to build your own containers. condor nominally can detect opencl devices, but the code hasn't really been tested in years and may no longer work properly. when testing in 2025, clinfo just worked with an intel pytorch container in apptainer without having to bind mount driver libraries from the host system like it is done for nvidia or amd. building your own container using the intel libraries is difficult and/or is a moving target. how much time one wants to spend on this given their gpu roadmap is unclear.

TAMU has a bunch of clusters available through ACCESS. the issue is that they have a pretty strict network policy. you can poke a hole for http traffic, but condor doesn't use http.

configs for unused / inactive sites can be found in `configs/unused_configs/`. 

## adding a new site

1. provision your account / allocation as instructed by the site.
2. stage the ospool image `.sif` (see [architecture.md](architecture.md)).
3. if the site has no native cvmfs, set up a `cvmfsexec` dist on shared storage (see [cvmfsexec.md](cvmfsexec.md)).
4. write a new config (or two, if you're running separate cpu and gpu glideins). you can use existing ones as a reference, though make sure to carefully read their docs and account for any particulars they mention.
5. submit one task by hand to test, iterate if needed until all looks good and your glidein successfully ran some condor jobs to completion.
6. write a submit script and make sure to include any necessary cleanup steps to avoid bloating disk usage.
7. if the site allows (s)cronjobs, get that set up to keep things topped up. check back later to make sure it actually runs as expected.
8. update any relevant docs and write down weirdness you discovered along the way.
9. you should be all set! keep an eye on things, especially early on. there's always sneaky dragons trying to burn you....
