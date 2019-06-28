# Configuration Index

List of available configuration options.

## [Mode]

* debug: True/False. Set whether in debug mode or not (Don't know what debug does though...?)
* dryrun: True/False. Doesn't actually submit jobs.

## [Glidein]

* address: Address of the glidein server, which keeps track of the global condor queue.
* uuid: The UUID of the glidein.
* site: Name of the site this config is for (ex. Cedar)
* delay: How long to wait before considering the next set of jobs; if client.py should be run by cron, then use -1

## [Cluster]

* user: User under which jobs are being submitted.
* os: The name of the OS on the cluster (ex. RHEL6, Ubuntu_16.04).
* cvmfs: True/False. Whether the site has access to cvmfs or not.
* limit_per_submit: The max number of jobs that can be submitted at once.
* submit_command: Command used to submit jobs on this cluster (ex. condor_submit, sbatch...)
* mem_only: True/False. Set only mem requirement for PBS (default: False).
* vmem_only: True/False. Virtual memory only; applies to PBS-like clusters.
* set_gpu_req: True/False. Set gpus requirement for PBS (default: True).
* scheduler: Name of scheduler (ex. slurm, HTCondor, LSF...)
* walltime_hrs: Max number of hours to run as integer (may not be enforced)
* group_jobs: True/False. Submits multiple glideins with the same config.
* running_cmd: Command needed to determine number of jobs running (ex. squeue ...).
* partitions: ExamplePartition (Where ExamplePartition correspond to labelled section below). User-defined configurations included in this file.
* pmem_only: True/False. Physical memory; a compliment to vmem_only.
* pvmem: True/False. ???
* prioritize_jobs: Array of strings representing priorities in order of priority (ex. ["memory", "disk"])
* node_property: ???
* cleanup: True/False. Whether to cleanup after finishing or not.
* dir_cleanup: Absolute path to directory to clean.

## [ExamplePartition]

* cpu_only: True/False. If only CPUs are used or not.
* gpu_only: True/False. If only GPUs are used or not.
* max_cpus_per_job: Max number of CPUs to use for each job.
* max_gpus_per_job: Max number of GPUs to use for each job.
* max_memory_per_job: Max number of Megabytes of memory to use for each job.
* max_disk_per_job: Max number of Megabytes of disk space to use per job.
* whole_node: True/False. Use a fixed size of resources.
* whole_node_cpus: The amount of CPUs for the glidein.
* whole_node_gpus: The amount of GPUs for the glidein.
* whole_node_memory: Number of Megabytes of memory for glidein.
* mem_per_core: Number of Megabytes of memory per allocated per core.
* whole_node_disk: Number of Megabytes of disk space.
* running_cmd: Command needed to determine number of jobs running.
* idle_cmd: Command needed to determine number of jobs idle.
* max_total_jobs: Number of total jobs in any state as integer.
* max_idle_jobs: Number of jobs that can be in idle state as integer.
* limit_per_submit: Number of jobs that can be submitted per run as integer.
* submit_command: Command to issue on submission.

## [SubmitFile]

* log: Absolute path to log file for submission.
* filename: The name of the submit file (ex. submit.pbs)
* env_wrapper_name: Name of the env_wrapper file to clean the environment (and sets variables).
* requirements: List of requirements for submission (ex. CUDACapability)
* executable: Absolute path to executable to be run.
* custom_middle: Custom extra line(s) needed for cluster.
* custom_end: Custom extra line(s) needed at the end of job.
* mem_scale: Conversion from KB to MB, because LSF scheduler uses KB values but we need MB by default.
* local_dir: Absolute path to temporary directory that will be used.
* gpu_submit: GPU request command.
* custom_header: To add something to the submit file BEFORE the automated entry (prefix on the submit file)
* ref_host: ???
* mem_safety_scale: ???

## [StartdChecks]

* enable_startd_checks: True/False.  Enable or disable Startd monitoring checks. 

## [StartdLogging]

* bucket: String.  Name of S3 bucket
* send_startd_logs: True/False.  Send Startd Logs to S3 endpoint
* url: String.  URL of S3 endpoint.

## [CustomEnv]

* **List custom environment variables here**
* http_proxy: The address to a required proxy.
* SINGULARITY_BIN: The absolute path to singularity (for use in container configs)
* CONTAINER: The absolute path to the singularity image to use.
* GROUP: This corresponds to the Affiliation classad in the Condor job. This is for ranking ONLY. (ex. Alberta)
