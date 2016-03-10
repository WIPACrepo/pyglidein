# Server

The server has two components, one to check on queue status and one
to present the status to clients.

# Queue Status

`condor_q` is used to retrieve the queue status (idle jobs). Attributes
recorded are:

* RequestCPUs
* RequestMemory
* RequestDisk
* RequestGPUs
* OpSysAndVer

This is on a timer to refresh once every 5 minutes.

# Web Server

A web server is used to display the queue status to the world. Clients
use jsonrpc over http to get the entire queue status.

A standard http view is also available for human monitoring:

![http view](list_of_requirements.png)
