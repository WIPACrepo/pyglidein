# Configuration Index

List of available configuration options.

## [Cluster]
mem_only: True/False. Set only mem requirement for PBS (default: False).
set_gpu_req: True/False. Set gpus requirement for PBS (default: True).

## [StartdChecks]

* enable_startd_checks: True/False.  Enable or disable Startd monitoring checks. 

## [StartdLogging]

* bucket: String.  Name of S3 bucket
* send_startd_logs: True/False.  Send Startd Logs to S3 endpoint
* url: String.  URL of S3 endpoint.
