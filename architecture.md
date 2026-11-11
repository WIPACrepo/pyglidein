# architecture

## the container

we are using the default OSG container. this handles most of the complexity for us, we "just" have to configure it.

- image: `docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release`
- source: `https://github.com/opensciencegrid/osgvo-docker-pilot`

to create a `.sif` file for apptainer, run the following command:  
`apptainer pull docker://hub.opensciencegrid.org/osg-htc/ospool-ep:25-cuda_11_8_0-release`

notably, this results in a container-in-container setup. the glidein runs a container and user jobs run their own container inside it. some sites do not support that out of the box, so some convincing has to happen to make sure everything still works. more on that below.

relevant OSG documentation:  
- [user-launched containers](https://opensciencegrid.org/docs/resource-sharing/user-containers/)
  -- our exact pattern: pilot container inside a slurm job
- [backfill containers](https://opensciencegrid.org/docs/resource-sharing/os-backfill-containers/)
  -- more detailed configuration docs

## glidein lifecycle

like all things in life, glideins too, die only to be born anew. here's a sketch of how that usually plays out:

  - manually or through a (s)cronjob `helpers/submit_<site>.sh` is run, which then:
  - submits a new array of glidein jobs if needed, by running `sbatch configs/<site>.slurm`
  - now it's up to the cluster to schedule these glidein jobs
  - once started, it will:
    - set configuration env vars
    - create a scratch dir and copy `glidein_start.sh` into it
    - run `glidein_start.sh`, which then starts the container
    - condor startd joins the `glidein-cm.icecube.wisc.edu` pool
    - the glidein will then keep accepting and running condor jobs as long as it has capacity
    - once it retires (or hits the idle timeout) it will clean up and exit

note: there is no feedback mechanism for deciding *how many* glideins to run. 
array size is hardcoded per payload, and the submit helper only checks whether the local queue is empty to ensure a consistent supply of pending jobs.
generally demand far outpaces supply, so this usually isn't a problem.


### like tears in the rain...

the ospool image takes three env vars that configure the lifetime:
- `ACCEPT_JOBS_FOR_HOURS`: how long it will accept new jobs for.
- `ACCEPT_IDLE_MINUTES`: if this time elapses without any new jobs, the glidein will preemptively exit to avoid wasting resources.
- `RETIREMENT_HOURS`: a grace period after the glidein has stopped accepting new jobs, to let running jobs finish.

slurm jobs also set a maximum walltime, when reached slurm will unceremoniously kill the glidein. 
in practice we set `ACCEPT_JOBS_FOR_HOURS` equal to the slurm walltime and ignore the retirement window altogether.
in practice this works because glideins only ever accept jobs with an `OriginalTime` lower than the remaining glidein walltime. 
though this is a somewhat nonstandard setup.


## configuration / env vars

individual sites are configured through env vars that are set in the slurm script and passed along to `glidein_start.sh`. which in turn configures the ospool container. 
this list is not exhaustive, but covers the more commonly used settings.

- `TOKEN`: auth token to connect to the condor pool
- `GLIDEIN_Site`: name of the cluster (this should match OSPool)
- `CPUS`: number of available cores
- `GPUS`: number of available GPUs
- `MEMORY`: available RAM in MiB 
- `DISK`: available disk space in KiB (TODO: this may be unused?)
- `ACCEPT_JOBS_FOR_HOURS`: how long the glidein will accept new jobs for
- `ACCEPT_IDLE_MINUTES`: early exit threshold if glidein sits idle for too long 

- `SINGULARITY_BIN`: apptainer binary location (default `apptainer`)
- `BASE_IMAGE`: .sif image location
- `NEED_CONDOR_EXTRA_ATTR`: if set to `true` this passes along a `extra-attributes.cfg` file to the container. used to manually set CUDA capability levels for MIG gpu slices, since condor can't reliably detect those itself in that case.

(if needed, env vars can also be passed to the container directly, bypassing `glidein_start.sh`, by prefixing them with `APPTAINERENV_`.)
